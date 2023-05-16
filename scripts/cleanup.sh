#!/bin/bash

clear_previous_runs(){
    #clear previous runs
    running_instance=$(sudo docker ps -aq)
    if [-z "$running_instance"]
    then
        sudo docker stop $running_instance
    fi
    if (( $number_of_images > $max_number_of_images )); then
        echo "Maximum number of image found. Clearing OS"
        sudo docker rmi $(sudo docker images -q)
    else
        echo "Number of allowed images $number_of_images/$max_number_of_images"
    fi
}