#!/bin/bash

#Global Variables
export root_path=$(pwd)$(echo /)

#Local Variables
container_dockerfile_directory="container_images/docker_files/"
container_dockercompose_directory="container-images/docker_compose/"
scripts_directory="scripts/"
setup_script="setup.sh"


#Include Scripts
source $root_path$scripts_directory"setup.sh"

echo $root_path$container_dockerfile_directory
echo $root_path$container_dockercompose_directory
echo $root_path$scripts_directory
