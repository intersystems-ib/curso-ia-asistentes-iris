ARG IMAGE=docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2027.1.0AI.109.0
FROM $IMAGE

USER root

# create directory to copy files into image
WORKDIR /opt/irisapp
RUN chown -R irisowner:irisowner /opt/irisapp

USER irisowner

# copy files to image
WORKDIR /opt/irisapp
COPY --chown=irisowner:irisowner iris.script iris.script
COPY --chown=irisowner:irisowner src src

# run iris.script
RUN iris start IRIS \
    && iris session IRIS < /opt/irisapp/iris.script \
    && iris stop IRIS quietly
