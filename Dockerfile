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

ARG LOCALIZATION_RELEASE_REVISION=d02c527b4a35de766f971a61351e23ca07d15e22
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

ARG PRISM_RELEASE_REVISION=e685fa36f8a0b03ab14b5454e49d1976183401c8
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
ARG BASE_REVISION=0879caee18c8f4d4e8ba0ca18fa387f7114dd1eb
RUN git pull && git checkout $BASE_REVISION \
  && mvn verify clean --fail-never \
  && git clean -df
RUN git pull && git checkout $BASE_REVISION \
  && mvn clean install -P -dist -DskipTests=true \
  && git clean -df

# Build with release version
ARG RELEASE_REVISION=5185c1a165a185bb25efe221f2a41139ee630ac3
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

