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

ARG LOCALIZATION_RELEASE_REVISION=a7e8e5a24f71b81a68017711c1943debdfdb6e03
RUN git pull && git checkout $LOCALIZATION_RELEASE_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 as prism

# Build prism
WORKDIR /build
RUN git clone --branch support-4.8 --single-branch https://github.com/Evolveum/prism

WORKDIR /build/prism

ARG PRISM_RELEASE_REVISION=d557a886e8546b6dcda6dabb6f10c8661b9efe04
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
ARG BASE_REVISION=v4.8.8
RUN git pull && git checkout $BASE_REVISION \
 && mvn verify clean --fail-never \
 && git clean -df
RUN git pull && git checkout $BASE_REVISION \
 && mvn clean install -P dist -DskipTests=true \
 && git clean -df

# Build with release version
ARG RELEASE_REVISION=4583b4fc9dc40ea9d9afdf502e696f7959b245f8
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

