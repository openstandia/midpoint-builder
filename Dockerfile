FROM maven:3.9.5-eclipse-temurin-17 AS localization

# Build midpoint-localization
WORKDIR /build
RUN git clone --branch support-4.10 --single-branch https://github.com/Evolveum/midpoint-localization

WORKDIR /build/midpoint-localization

# ARG LOCALIZATION_BASE_REVISION=v4.4
# RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
#   && mvn verify clean --fail-never \
#   && git clean -df
# RUN git pull && git checkout $LOCALIZATION_BASE_REVISION \
#   && mvn clean install \
#   && git clean -df

ARG LOCALIZATION_RELEASE_REVISION=a34d2493a17a96a43754ebe79a99cc0e72d1c69d
RUN git pull && git checkout $LOCALIZATION_RELEASE_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 AS prism

# Build prism
WORKDIR /build
RUN git clone --branch support-4.10 --single-branch https://github.com/Evolveum/prism

WORKDIR /build/prism

ARG PRISM_RELEASE_REVISION=db4d7514afc8cb367c4a572f0a70cf5c2540ce62
RUN git pull && git checkout $PRISM_RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 AS builder

# Build midpoint
WORKDIR /build
RUN git clone --branch support-4.10 --single-branch https://github.com/Evolveum/midpoint

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
ARG BASE_REVISION=v4.10.3
RUN git pull && git checkout $BASE_REVISION \
 && mvn verify clean --fail-never \
 && git clean -df
RUN git pull && git checkout $BASE_REVISION \
 && mvn clean install -P dist -DskipTests=true \
 && git clean -df

# Build with release version
ARG RELEASE_REVISION=5f665a20f7462591b5f1dd617c438610fd148768
RUN git pull && git checkout $RELEASE_REVISION \
  && mvn clean install -P dist -DskipTests=true \
  && git clean -df

# Define base image tag
ARG BASE_IMAGE_TAG=4.10

# Create VERSION file
RUN git rev-parse HEAD > /build/VERSION.txt

# Cache dependencies for building extenxion
WORKDIR /build/extension/
ADD pom.xml /build/extension/
RUN mvn clean install


FROM maven:3.9.5-eclipse-temurin-17

WORKDIR /build

# Copy maven local repository
COPY --from=builder \
  /root/.m2 \
  /root/.m2

# Copy midpoint.jar
COPY --from=builder \
  /build/midpoint/gui/midpoint-jar/target/midpoint.jar \
  /build/

# Copy ninja.jar
COPY --from=builder \
  /build/midpoint/tools/ninja/target/ninja.jar \
  /build/

# Copy VERSION.txt
COPY --from=builder \
  /build/VERSION.txt \
  /build/
