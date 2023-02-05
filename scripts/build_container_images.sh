#!/bin/bash

# recieves that path of the docker file and builds an image
build_image_from_dockerfile()
{
    image_name=$(echo "$1" | rev | cut -d/ -f2 | rev)
    cd $1 && docker buildx build --platform=linux/amd64 -t $image_name .
}