FROM ubuntu:24.04

# Image labels
ARG IMAGE_CREATED
ARG GIT_DIGEST

LABEL org.opencontainers.image.created=$IMAGE_CREATED
LABEL org.opencontainers.image.revision=$GIT_DIGEST
LABEL org.opencontainers.image.version="0.1.0"
LABEL org.opencontainers.image.authors="harmen@datalab.nl"
LABEL org.opencontainers.image.vendor="DatalabFabriek B.V."
LABEL org.opencontainers.image.title="Datalab Notion Backup"

# Volumes
VOLUME /dllog
VOLUME /dlstore

# Install utilities
RUN apt-get update && apt-get install -y wget curl nano unzip jq cron

# Copy stuff into the container
RUN mkdir -p /datalab
COPY scripts/ /datalab/
RUN chmod +x /datalab/*.sh
COPY dev/.env /datalab/

# Reset the workdir
WORKDIR /datalab

# Start up with this script
ENTRYPOINT /datalab/entrypoint.sh