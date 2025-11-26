FROM maven:3.9.5-eclipse-temurin-17 as localization

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

ARG LOCALIZATION_RELEASE_REVISION=fb3b6cf022570cb4cc32dd411eb26d3ee10870ba
RUN git pull && git checkout $LOCALIZATION_RELEASE_REVISION \
  && mvn clean install \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 as prism

# Build prism
WORKDIR /build
RUN git clone --branch support-4.10 --single-branch https://github.com/Evolveum/prism

WORKDIR /build/prism

ARG PRISM_RELEASE_REVISION=4917eaff743a6be9ea7224660556371083bc0b00
RUN git pull && git checkout $PRISM_RELEASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df


FROM maven:3.9.5-eclipse-temurin-17 as builder

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
ARG BASE_REVISION=v4.10
RUN git pull && git checkout $BASE_REVISION \
 && mvn verify clean --fail-never \
 && git clean -df
RUN git pull && git checkout $BASE_REVISION \
 && mvn clean install -P dist -DskipTests=true \
 && git clean -df

# Build with release version
ARG RELEASE_REVISION=b3526859f8b5a554561de6c551422a707b9be18d
RUN git pull && git checkout $RELEASE_REVISION \
  && mvn clean install -P dist -DskipTests=true \
  && mv gui/midpoint-jar/target/midpoint.jar /build/midpoint.jar \
  && git clean -df

# Define base image tag
ARG BASE_IMAGE_TAG=4.10

# Create VERSION file
RUN git rev-parse HEAD > /build/VERSION.txt

# Cache dependencies for building extenxion
WORKDIR /build/extension/
ADD pom.xml /build/extension/
RUN mvn clean install

