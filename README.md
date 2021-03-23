# MidPoint Builder

## Description

This project is for building [midPoint](https://github.com/Evolveum/midpoint) from the source.
Docker image which contains `midpoint.war` and cached maven repository for the dependencies is created by this project.
You can use this docker image with mutli-stage build to get the war file. Also, you can use it as build environment for building your midPoint extension.


## Build

```
docker build -t midpoint-builder .
```


## License

Licensed under the [Apache License 2.0](/LICENSE).
