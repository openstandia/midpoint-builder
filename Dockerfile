FROM maven:3.6.2-jdk-11 as localization

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.3 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

ARG LOCALIZATION_REVISION=4e616912951821a3992ff50595441a9a7e5169b8
RUN git pull && git checkout $LOCALIZATION_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.6.2-jdk-11 as builder

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.3 --single-branch https://github.com/Evolveum/midpoint

WORKDIR /build/midpoint

# Cache dependencies with base version
#ARG BASE_REVISION=v4.3
# v4.3, v4.3.1 can't build now due to jasper report repository change
ARG BASE_REVISION=73806a2c1ed430d60777639eb06fb3f3f42ee70f
RUN git pull && git checkout $BASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df

# Copy midpoint-localization
COPY --from=localization \
  /root/.m2/repository/com/evolveum/midpoint/midpoint-localization/ \
  /root/.m2/repository/com/evolveum/midpoint/midpoint-localization/

# Build with release version
ARG RELEASE_REVISION=3851d1470dc1f251cf24f343ba30256e4625b6e1
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

