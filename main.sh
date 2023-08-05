#!/bin/bash

#Global Variables
root_path=$(pwd)$(echo /)
cur_user="$(id -u -n)"
os_architecture="$(uname -p)"
os_system="$(uname -s)"
number_of_images=$(sudo docker images | awk 'END { print NR }')
max_number_of_images="30"
running_docker_instance=$(sudo docker ps -aq)
network_interface="lab-net"

#directories
container_dockerfile_directory="container_images/docker_files/"
container_dockercompose_directory="container_images/docker_compose/"

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

#lists
base_images_list=("arm64v8/centos:7" "arm64v8/ubuntu:xenial-20170510" "kalilinux/kali-rolling:latest" "ubuntu:14.04")
dockerfile_list=($centos1 $ftp_anon $kali_linux $proftpd)
dockercompose_list=($activemq_CVE_2015_5254 $activemq_CVE_2016_3088 $airflow_CVE_2020_11978 $airflow_CVE_2020_11981 
                    $airflow_CVE_2020_17526 $appweb_CVE_2018_8715 $aria2_rce $coldfusion_CVE_2010_2861
                    $couchdb_CVE_2017_12635 $couchdb_CVE_2022_24706 $dns_zone_transfer $docker_smtp
                    $flask_ssti $log4j_CVE_2021_44228 $mongo_express_CVE_2019_10758 $mysql_CVE_2012_2122
                    $mysql_CVE_2012_2122 $openssh $redis_rce_master_slave $samba_CVE_2017_7494
                    $shellshock_CVE_2014_6271 $ssh_CVE_2018_15473 $ssh_CVE_2018_15473 $tomcat_CVE_2020_1938
                    $weblogic_ssrf)

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

label_center()
{
    lenght_of_string=$(($(echo $1 | wc -m) - 1))
    columns=80
    front_spacing=$(($(($columns - $lenght_of_string)) / 2 ))
    back_spacing=$(($front_spacing + $lenght_of_string))
    number_of_front_sympols=5
    number_of_characters_before_back_sympols=76
    for i in $(seq 1 $columns); do echo -n "="; done
    echo ""
    for i in $(seq 1 $columns); do
    {
        if [[ $i -le $number_of_front_sympols ]]
        then
            echo -n "="
        fi

        if [[ $i -lt $front_spacing ]] && [[ $i -gt $number_of_front_sympols ]] 
        then
            echo -n " "
        fi

        if [[ $i -eq $front_spacing ]]
        then
            echo -n $1
        fi

        if [[ $i -gt $back_spacing ]]
        then
        {
            if [[ $i -le $number_of_characters_before_back_sympols ]]
            then
                echo -n " "
            elif [[ $i -gt $number_of_characters_before_back_sympols ]]
            then
                echo -n "="
            fi
        }
        fi
        if [[ $i -eq $columns ]]
        then
            echo -n "="
        fi
    }
    done
    echo ""
    for i in $(seq 1 $columns); do echo -n "="; done
    echo ""
}

build_docker_network(){
    lab_net_exist="$(sudo docker network ls | grep $network_interface)"
    if [[ ! -z "$lab_net_exist" ]]; then
    {
        sudo docker network rm $network_interface
        sudo docker network create --driver bridge $network_interface
    }
    else
    {
        sudo docker network create --driver bridge $network_interface
    }
    fi
    
}

check_for_null_variables(){
    if [ -z "$1" ]; then
    {
        echo "Variable $2 is not set - exiting"
        exit
    }
    else
    {
        echo "Variable $2 set!"
    }  
    fi    
}

pull_base_images(){
    for base_image_list_item in ${base_images_list[@]}; do
    {
        if [[ -z "$(docker images | awk '{print $1":"$2}' | grep $base_image_list_item)" ]]
        then
        {
            echo "Pulling $base_image_list_item"
            docker pull $base_image_list_item
        }
        else
            echo "Image $base_image_list_item FOUND!"
        fi
    }
    done
}

# recieves that path of the docker file and builds an image
build_image_from_dockerfile()
{
    image_name=$(echo "$1" | rev | cut -d/ -f2 | rev)
    image_exist=false
    current_images_array=()
    while IFS= read -r line; do
        current_images_array+=( "$line" )
    done < <( sudo docker images | awk '{print $1}' )

    for image_name_item in ${current_images_array[@]}; do
        if [[ "$image_name_item" == $image_name ]]
        then
            $image_exist = true
        fi
    done

    if [ $image_exist = false ]
    then
        cd $1 && sudo docker buildx build --platform=linux/arm64 -t $image_name .
    fi
}

build_images_with_docker_file(){
    for dockerfile_list_item in ${dockerfile_list[@]}; do
        build_image_from_dockerfile $dockerfile_list_item
    done
}

build_and_run_images_with_docker_compose(){
    for docker_compose_list_item in ${dockercompose_list[@]}; do
    {
        cd $docker_compose_list_item && sudo docker compose up -d
    }
    done
}

run_images_with_docker_file(){
    sudo docker run -d \
        --privileged \
        --name centos1 \
        --network $network_interface \
        centos1
    
    sudo docker run -d \
        --privileged \
        --name ftp-anon \
        --network $network_interface \
        --publish 20-21/tcp \
        --publish 65500-65515/tcp \
        --volume "$ftp_anon"/mount_partition:/var/ftp:ro \
        ftp_anon
    
    sudo docker run -d \
        --privileged \
        --name proftpd_1_3_5 \
        --network $network_interface \
        --publish 21/tcp \
        --publish 80/tcp \
        proftpd
}

get_lab_info_on_running_instances()
{
    sudo docker inspect lab-net | grep -C3 "IPv4Address"
}

start_kali_with_interactive_shell(){
    sudo docker run -it \
        --name kalilinux 
        --network $network_interface \
        -v "$kali_linux"kali_share_folder:/root/kali_share_folder \
        kali_linux /bin/bash
}

run_images()
{
    run_images_with_docker_file
    #build_and_run_images_with_docker_compose
    #get_lab_info_on_running_instances
    #start_kali_with_interactive_shell
}

check_current_build(){
    echo "Need to check current build somehow"
}

clean_up_everything(){
    #clear previous runs
    if [ -z "$running_docker_instance" ]
    then
    {
        while IFS= read -r line; do
            sudo docker stop $line
            echo "Stoping container with id $line"
        done <<< "$running_docker_instance"
    }
    fi
    #$number_of_images > $max_number_of_images 
    if [ "$number_of_images" -gt "0" ]; then
    {
        sudo docker image prune -a -f
        sudo docker volume prune -f
        sudo docker system prune --volumes
        sudo docker rmi $(sudo docker images -q)
    }
    fi
}

option_1(){
    echo "Not done yet"
}

option_2(){
    label_center "START - CHECKING CURRENT BUILD"
    check_current_build
    label_center "END - CHECKING CURRENT BUILD"
    label_center "START - CREATING DOCKER NETWORKING COMPONENTS"
    build_docker_network
    label_center "END - CREATING DOCKER NETWORKING COMPONENTS"
    label_center "START - PULLING BASE IMAGES"
    pull_base_images
    label_center "END - PULLING BASE IMAGES"
    label_center "START - BUILDING CONTAINERS WITH DOCKER FILES"
    build_images_with_docker_file
    label_center "END - BUILDING CONTAINERS WITH DOCKER FILES"
    label_center "START - ADDING IMAGES TO THE ENVIROMENT"
    run_images
    label_center "END - ADDING IMAGES TO THE ENVIROMENT"
}

option_3(){
    echo "Not done yet"
}

option_4(){
    echo "Not done yet"
}

option_5(){
    label_center "START - CLEARING DOCKER ENVIROMENT"
    clean_up_everything $number_of_images $max_number_of_images $running_docker_instance
    label_center "END - CLEARING DOCKER ENVIROMENT"
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
        echo "    	1  -  About"
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
            1 ) option_1 ; exit ;;
            2 ) option_2 ; exit ;;
            3 ) option_3 ; exit ;;
            4 ) option_4 ; exit ;;
            5 ) option_5 ; exit ;;
            6 ) echo "Exiting Security Learning Hub"; exit ;;
            * ) ;;
        esac
    done
}

#start_services

#build_images_with_docker_file

menu