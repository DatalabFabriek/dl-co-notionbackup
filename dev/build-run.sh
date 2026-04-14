#!/bin/bash

# Check that this file is run from the project root
if [ ! -f ./Dockerfile ]; then
    echo "Please run this script from the project root where Dockerfile is located."
    exit 1
fi

# Check .env existence, if not, exit with an error message
if [ ! -f ./dev/.env ]; then
    echo "No ./dev/.env file found. Please create one with the necessary environment variables."
    exit 1
fi

docker build -t dl-co-notionbackup:dev . -f Dockerfile
docker run -it --rm --name dl-co-notionbackup -v ./dev/.env:/datalab/mounted.env dl-co-notionbackup:dev

