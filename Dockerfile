FROM maven:3.6.2-jdk-11 as builder

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.2 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

ARG LOCALIZATION_REVISION=2c1a85295cae14aa708fba461bdf2429fee4cbd6
RUN git pull && git checkout $LOCALIZATION_REVISION \
  && mvn clean install \
  && git clean -df

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.2 --single-branch https://github.com/Evolveum/midpoint

WORKDIR /build/midpoint

# Cache dependencies with base version
ARG BASE_REVISION=v4.2
RUN git pull && git checkout $BASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df

# Cache dependencies with release version
ARG RELEASE_REVISION=984b212708dff3657dcd8f2ddcb4e2eb13871156
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

