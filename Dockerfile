FROM maven:3.6.2-jdk-11 as builder

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.0 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

ARG LOCALIZATION_REVISION=192cc5b3790d4d2761c861fdeed25f6ea975b9d4
RUN git pull && git checkout $LOCALIZATION_REVISION \
  && mvn clean install \
  && git clean -df

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.0 --single-branch https://github.com/Evolveum/midpoint

WORKDIR /build/midpoint

# Cache dependencies with base version
ARG BASE_REVISION=v4.0.4
RUN git pull && git checkout $BASE_REVISION \
  && sed -i -e "s|<repositories>|<repositories><repository><id>jaspersoft-third-party</id><name>Jasper</name><url>https://jaspersoft.jfrog.io/jaspersoft/third-party-ce-artifacts</url></repository>|" pom.xml \
  && mvn clean install -P -dist -DskipTests=true \
  && git reset --hard HEAD \
  && git clean -df

# Cache dependencies with release version
ARG RELEASE_REVISION=7d9849624d3fee6904405d92b69c395190468db2
RUN git pull && git checkout $RELEASE_REVISION \
  && sed -i -e "s|<repositories>|<repositories><repository><id>jaspersoft-third-party</id><name>Jasper</name><url>https://jaspersoft.jfrog.io/jaspersoft/third-party-ce-artifacts</url></repository>|" pom.xml \
  && mvn clean install -P -dist -DskipTests=true \
  && mv gui/admin-gui/target/midpoint-executable.war /build/midpoint.war \
  && git reset --hard HEAD \
  && git clean -df

# Create VERSION file
RUN git rev-parse HEAD > /build/VERSION.txt

# Cache dependencies for building extenxion
WORKDIR /build/extension/
ADD pom.xml /build/extension/
RUN mvn clean install

