#!/bin/bash

#Global Variables
export root_path=$(pwd)$(echo /)
export cur_user="$(id -u -n)"
export os_architecture="$(uname -p)"
export os_system="$(uname -s)"

#Directories
container_dockerfile_directory="container_images/docker_files/"
container_dockercompose_directory="container-images/docker_compose/"
scripts_directory="scripts/"
#scripts
setup_script="setup.sh"
build_image_script="build_container_images.sh"
cleanup_script="cleanup.sh"
#images with Dockerfile
centos1=$root_path$container_dockerfile_directory"centos1/"
ftp_anon=$root_path$container_dockerfile_directory"ftp_anon/"
kali_linux=$root_path$container_dockerfile_directory"kali_linux/"
proftpd=$root_path$container_dockerfile_directory"proftpd/"
#images with docker compose
activemq_CVE_2015_5254=$root_path$container_dockercompose_directory"activemq-CVE-2015-5254/"
activemq_CVE_2016_3088=$root_path$container_dockercompose_directory"activemq-CVE-2016-3088/"
airflow_CVE_2020_11978=$root_path$container_dockercompose_directory"airflow-CVE-2020-11978/"
airflow_CVE_2020_11981=$root_path$container_dockercompose_directory"airflow-CVE-2020-11981/"
airflow_CVE_2020_17526=$root_path$container_dockercompose_directory"airflow-CVE-2020-17526/"
appweb_CVE_2018_8715=$root_path$container_dockercompose_directory"appweb-CVE-2018-8715/"
aria2_rce=$root_path$container_dockercompose_directory"aria2-rce/"
coldfusion_CVE_2010_2861=$root_path$container_dockercompose_directory"coldfusion-CVE-2010-2861/"
couchdb_CVE_2017_12635=$root_path$container_dockercompose_directory"couchdb-CVE-2017-12635/"
couchdb_CVE_2022_24706=$root_path$container_dockercompose_directory"couchdb-CVE-2022-24706/"
dns_zone_transfer=$root_path$container_dockercompose_directory"dns-zone-transfer/"
docker_smtp=$root_path$container_dockercompose_directory"docker-smtp/"
flask_ssti=$root_path$container_dockercompose_directory"flask-ssti/"
log4j_CVE_2021_44228=$root_path$container_dockercompose_directory"log4j-CVE-2021-44228/"
mongo_express_CVE_2019_10758=$root_path$container_dockercompose_directory"mongo-express-CVE-2019-10758/"
mysql_CVE_2012_2122=$root_path$container_dockercompose_directory"mysql-CVE-2012-2122/"
openssh=$root_path$container_dockercompose_directory"openssh/"
redis_rce_master_slave=$root_path$container_dockercompose_directory"redis-rce-master-slave/"
samba_CVE_2017_7494=$root_path$container_dockercompose_directory"samba-CVE-2017-7494/"
shellshock_CVE_2014_6271=$root_path$container_dockercompose_directory"shellshock-CVE-2014-6271/"
ssh_CVE_2018_15473=$root_path$container_dockercompose_directory"ssh-CVE-2018-15473/"
tomcat_CVE_2020_1938=$root_path$container_dockercompose_directory"tomcat-CVE-2020-1938/"
weblogic_ssrf=$root_path$container_dockercompose_directory"weblogic-ssrf/"

#Include Scripts
source $root_path$scripts_directory$setup_script
source $root_path$scripts_directory$build_image_script
source $root_path$scripts_directory$cleanup_script

start_services(){
    if [[ "$os_system" = "Darwin" ]]
    then
        open -a Docker
    elif [[ "$os_system" = "Linux" ]]
    then
        sudo service docker start
    else
        echo "Unsupported OS System"
    fi
}

pull_base_images(){
    base_images_list=("centos:7" "metabrainz/base-image:latest" "kalilinux/kali-rolling:latest" "ubuntu:14.04")
    for base_image_list_item in ${base_images_list[@]}; do
        docker pull $base_image_list_item
    done
}

build_images_with_docker_file(){
    dockerfile_list=($centos1 $ftp_anon $kali_linux $proftpd)
    for dockerfile_list_item in ${dockerfile_list[@]}; do
        build_image_from_dockerfile $dockerfile_list_item
    done
}

option_1(){
    echo "Not done yet"
}

option_2(){
    echo "Not done yet"
}

option_3(){
    echo "Not done yet"
}

option_4(){
    echo "Not done yet"
}

option_5(){
    echo "Not done yet"
}

menu() {
    until [ "$selection" = "0" ]; do
        clear
        echo "
        
            _                           _               _                             _               
           | |                         (_)_            | |                           (_)              
            \ \   ____ ____ _   _  ____ _| |_ _   _ ___| |      ____ ____  ____ ____  _ ____   ____   
             \ \ / _  ) ___) | | |/ ___) |  _) | | (___) |     / _  ) _  |/ ___)  _ \| |  _ \ / _  |  
         _____) | (/ ( (___| |_| | |   | | |_| |_| |   | |____( (/ ( ( | | |   | | | | | | | ( ( | |  
        (______/ \____)____)\____|_|   |_|\___)__  |   |_______)____)_||_|_|   |_| |_|_|_| |_|\_|| |  
                                           _ (____/      _                                   (_____|  
                                          | |   | |     | |                                           
                                          | |__ | |_   _| | _                                         
                                          |  __)| | | | | || \                                        
                                          | |   | | |_| | |_) )                                       
                                          |_|   |_|\____|____/                                                                                                                                      
        "
        echo "      Author: Kyriakos Costa"
        echo "      Date: 22 January 2023"
        echo "      Version 6.0"
        echo "      Contact: kyriakoskosta@outlook.com"
        echo ""
        echo ""
        echo "    	1  -  Exit"
        echo "    	2  -  Network Security Lab"
        echo "    	3  -  Web Application Security Lab"
        echo "    	4  -  Email Security Lab"
        echo "    	5  -  Cleanup All Enviroments and Remove Installations"
        echo "    	6  -  Exit Security Learning Hub"
        echo ""
        echo -n "  Enter selection: "
        read selection
        echo ""
        case $selection in
            0 ) echo "Exiting UNic Security Hub"; exit ;;
            1 ) option_1 ; exit ;;
            2 ) option_2 ; exit ;;
            3 ) option_3 ; exit ;;
            4 ) option_4 ; exit ;;
            5 ) option_5 ; exit ;;
            * ) ;;
        esac
    done
}

#start_services
#pull_base_images
#build_images_with_docker_file

menu