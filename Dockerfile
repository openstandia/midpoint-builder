FROM maven:3.6.2-jdk-11 as builder

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.3 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

ARG LOCALIZATION_REVISION=v4.3
RUN git pull && git checkout $LOCALIZATION_REVISION \
  && mvn clean install \
  && git clean -df

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.3 --single-branch https://github.com/Evolveum/midpoint

WORKDIR /build/midpoint

# Cache dependencies with base version
ARG BASE_REVISION=v4.3
RUN git pull && git checkout $BASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df

# Cache dependencies with release version
ARG RELEASE_REVISION=4714974429c6aec783433f5aa830e0ea621ab9c7
RUN git pull && git checkout $RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && mv gui/admin-gui/target/midpoint-executable.war /build/midpoint.war \
  && git clean -df

# Create VERSION file
RUN git rev-parse HEAD > /build/VERSION.txt

# Cache dependencies for building extenxion
WORKDIR /build/extension/
ADD pom.xml /build/extension/
RUN mvn clean install

