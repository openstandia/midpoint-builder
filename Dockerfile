FROM maven:3.9.5-eclipse-temurin-17 as localization

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.8 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

# ARG LOCALIZATION_BASE_REVISION=v4.4
# RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
#   && mvn verify clean --fail-never \
#   && git clean -df
# RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
#   && mvn clean install \
#   && git clean -df

ARG LOCALIZATION_RELEASE_REVISION=9609d2315fc8c20f53505c4b31f11bbab4146f4d
RUN git pull && git checkout $LOCALIZATION_RELEASE_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 as prism

# Build prism
WORKDIR /build
RUN git clone --branch support-4.8 --single-branch https://github.com/Evolveum/prism

WORKDIR /build/prism

ARG PRISM_RELEASE_REVISION=dfd35ea5a7bddb7936859e27481376e5d5377fb0
RUN git pull && git checkout $PRISM_RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 as builder

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.8 --single-branch https://github.com/Evolveum/midpoint

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
ARG BASE_REVISION=v4.8.2
RUN git pull && git checkout $BASE_REVISION \
 && mvn verify clean --fail-never \
 && git clean -df
RUN git pull && git checkout $BASE_REVISION \
 && mvn clean install -P dist -DskipTests=true \
 && git clean -df

# Build with release version
ARG RELEASE_REVISION=155af25525db64fce88c865065036d185dcc89f6
RUN git pull && git checkout $RELEASE_REVISION \
  && mvn clean install -P dist -DskipTests=true \
  && mv gui/midpoint-jar/target/midpoint.jar /build/midpoint.jar \
  && git clean -df

# Define base image tag
ARG BASE_IMAGE_TAG=4.8

# Create VERSION file
RUN git rev-parse HEAD > /build/VERSION.txt

# Cache dependencies for building extenxion
WORKDIR /build/extension/
ADD pom.xml /build/extension/
RUN mvn clean install

