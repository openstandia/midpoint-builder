FROM maven:3.6.2-jdk-11 as builder

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.0 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

ARG LOCALIZATION_REVISION=1f14b863dfe49afbfe5fae16912cc382b9f0d31d
RUN git pull && git checkout $LOCALIZATION_REVISION \
  && mvn clean install \
  && git clean -df

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.0-multiaccount-outbound --single-branch https://github.com/openstandia/midpoint

WORKDIR /build/midpoint

# Cache dependencies with base version
ARG BASE_REVISION=v4.0.3
RUN git pull && git checkout $BASE_REVISION \
  && mkdir -p ~/.m2 \
  && echo '<settings><mirrors><mirror><id>jaspersoft-https</id><mirrorOf>jaspersoft-third-party</mirrorOf><url>https://jaspersoft.jfrog.io/jaspersoft/third-party-ce-artifacts/</url></mirror></mirrors></settings>' > ~/.m2/settings.xml \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df

# Cache dependencies with release version
ARG RELEASE_REVISION=37bb074a4e22d7b95d2b5938aeeb91959a3956ba
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

