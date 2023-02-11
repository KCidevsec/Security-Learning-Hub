#!/bin/bash

# recieves that path of the docker file and builds an image
build_image_from_dockerfile()
{
    image_name=$(echo "$1" | rev | cut -d/ -f2 | rev)
    current_images_array=()
    while IFS= read -r line; do
        current_images_array+=( "$line" )
    done < <( sudo docker images | awk '{print $1}' )

    for image_name in ${current_images_array[@]}; do
        if [[ "$image_name" == $1 ]]
        then
            cd $1 && docker buildx build --platform=linux/amd64 -t $image_name .
        fi
    done
}