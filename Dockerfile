FROM maven:3.6.2-jdk-11 as localization

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch master --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

ARG LOCALIZATION_BASE_REVISION=e1b5659d56560ce1115c03a61554631f9582f838
RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
  && mvn verify clean --fail-never \
  && git clean -df
RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
  && mvn clean install \
  && git clean -df

ARG LOCALIZATION_RELEASE_REVISION=bcb7e3affdf7b60fb432ae2d58dcb1d30e0a82ff
RUN git pull && git checkout $LOCALIZATION_RELEASE_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.6.2-jdk-11 as prism

# Build prism
WORKDIR /build
RUN git clone --branch master --single-branch https://github.com/Evolveum/prism

WORKDIR /build/prism

ARG PRISM_BASE_REVISION=6e55c1d465a0b0f755f074a15eade6a4acf8f98b
RUN git pull && git checkout $PRISM_BASE_REVISION \
  && mvn verify clean --fail-never \
  && git clean -df
RUN git pull && git checkout $PRISM_BASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df

ARG PRISM_RELEASE_REVISION=9f170ad694c4cde755c5b52ee6c296e523de892d
RUN git pull && git checkout $PRISM_RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df


FROM maven:3.6.2-jdk-11 as builder

# Build midpoint
WORKDIR /build
RUN git clone --branch master --single-branch https://github.com/Evolveum/midpoint

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
#ARG BASE_REVISION=e813c20aa62d0046d4085cf8d94bfdfe051f4fc5
#RUN git pull && git checkout $BASE_REVISION \
#  && mvn verify clean --fail-never \
#  && git clean -df
#RUN git pull && git checkout $BASE_REVISION \
#  && mvn clean install -P -dist -DskipTests=true \
#  && git clean -df

# Build with release version
ARG RELEASE_REVISION=bfdd31888d3de638540c715d7bd96b4b707e6f7c
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

