FROM maven:3.6.2-jdk-11 as localization

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.4 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

# ARG LOCALIZATION_BASE_REVISION=v4.4
# RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
#   && mvn verify clean --fail-never \
#   && git clean -df
# RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
#   && mvn clean install \
#   && git clean -df

ARG LOCALIZATION_RELEASE_REVISION=62976f2e2b6878a9a5fbc36045c7de77ff479562
RUN git pull && git checkout $LOCALIZATION_RELEASE_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.6.2-jdk-11 as prism

# Build prism
WORKDIR /build
RUN git clone --branch support-4.4 --single-branch https://github.com/Evolveum/prism

WORKDIR /build/prism

ARG PRISM_RELEASE_REVISION=0e19682a01f361381ab274f35654753949ee65ab
RUN git pull && git checkout $PRISM_RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df


FROM maven:3.6.2-jdk-11 as builder

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.4 --single-branch https://github.com/Evolveum/midpoint

WORKDIR /build/midpoint

# Copy midpoint-localization
COPY --from=localization \
  /root/.m2/repository/com/evolveum/midpoint/midpoint-localization/ \
  /root/.m2/repository/com/evolveum/midpoint/midpoint-localization/

# Copy midpoint-prism
COPY --from=prism \
  /root/.m2/repository/com/evolveum/prism/ \
  /root/.m2/repository/com/evolveum/prism/

# Cache dependencies with base version
ARG BASE_REVISION=v4.4.1
RUN git pull && git checkout $BASE_REVISION \
 && mvn verify clean --fail-never \
 && git clean -df
RUN git pull && git checkout $BASE_REVISION \
 && mvn clean install -P -dist -DskipTests=true \
 && git clean -df

# Build with release version
ARG RELEASE_REVISION=bc8e1c529def47aef260f38d1381d49e18a5278d
RUN git pull && git checkout $RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && mv gui/admin-gui/target/midpoint-executable.war /build/midpoint.war \
  && git clean -df

# Define base image tag
ARG BASE_IMAGE_TAG=4.4

# Create VERSION file
RUN git rev-parse HEAD > /build/VERSION.txt

# Cache dependencies for building extenxion
WORKDIR /build/extension/
ADD pom.xml /build/extension/
RUN mvn clean install

