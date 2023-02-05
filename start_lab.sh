#!/bin/bash

#start service
start_services(){
    sudo service docker start
}

set_global_variables(){
    #global variables
    echo "--------------------------------------------------------------------------------"
    echo "                         Setting Enviromental Variables"
    echo "--------------------------------------------------------------------------------"
    _architecture="$(uname -p)"
    _user="$(id -u -n)"
    root_path=$(pwd)$(echo /)
    number_of_images=$(sudo docker images | tee >(wc -l) | tail -1)
    max_number_of_images="35"
}

set_container_images_paths(){
    #global variables
    echo "--------------------------------------------------------------------------------"
    echo "                         Setting Contaier Image's Paths"
    echo "--------------------------------------------------------------------------------"
    kalilinux_folder="kali-linux/"
    centos1_folder="centos1"
    vulhub_path="vulhub/"
    flask_ssti_path="flask/ssti"
    activemq_2015_path="activemq/CVE-2015-5254"
    activemq_2016_path="activemq/CVE-2016-3088"
    apero_rce_path="apereo-cas/4.1-rce"
    appweb_2018_path="appweb/CVE-2018-8715"
    aria2_rce_path="aria2/rce"
    bash_shellshock_path="bash/CVE-2014-6271"
    coldfusion_2010_path="coldfusion/CVE-2010-2861"
    couchdb_2017_path="couchdb/CVE-2017-12635"
    oracle_sql_injection_2020_path="django/CVE-2020-9402"
    dns_zone_transf_path="dns/dns-zone-transfer"
    mysql_path="mysql/CVE-2012-2122"
    samba_path="samba/CVE-2017-7494"
    proftpd_path="proftpd"
    ftp_anon="ftp-anon"
    openssh_server="openssh"
    smtp_server="docker-smtp"
}

clear_previous_runs(){
    #clear previous runs
    echo "--------------------------------------------------------------------------------"
    echo "                              Cleaning Up Previous Run"
    echo "--------------------------------------------------------------------------------"
    sudo docker stop $(sudo docker ps -aq)
    sudo docker rm $(sudo docker ps -aq)
    if (( $number_of_images > $max_number_of_images )); then
        echo "Maximum number of image found. Clearing OS"
        sudo docker rmi $(sudo docker images -q)
    else
        echo "Number of allowed images $number_of_images/$max_number_of_images"
    fi
}

build_images(){
    #pulling required images
    echo "--------------------------------------------------------------------------------"
    echo "                        Downloading Required Images"
    echo "--------------------------------------------------------------------------------"
    sudo docker pull sameersbn/bind:9.9.5-20170129
    sudo docker pull juanluisbaptiste/postfix
    sudo docker pull tvial/docker-mailserver:latest

    #build fresh images
    echo "--------------------------------------------------------------------------------"
    echo "                            Building fresh images"
    echo "--------------------------------------------------------------------------------"
    cd $root_path$kalilinux_folder && sudo docker build -t my-kali .
    cd $root_path$centos1_folder && sudo docker build -t my-centos1 .
    cd $root_path$proftpd_path && docker buildx build --platform=linux/amd64 -t proftp .
    cd $root_path$ftp_anon && sudo docker buildx build --platform=linux/amd64 -t docker-anon-ftp .
}

create_interfaces(){
    #creating network interface
    echo "--------------------------------------------------------------------------------"
    echo "                          Building Network Interfaces"
    echo "--------------------------------------------------------------------------------"
    sudo docker network rm lab-net
    sudo docker network create --driver bridge lab-net
}

starting_smtp_env(){
    #starting containers
    echo "--------------------------------------------------------------------------------"
    echo "                              Starting Containers"
    echo "--------------------------------------------------------------------------------"

    #smtp server
    cd $root_path$smtp_server && sudo docker compose up -d mail
    id=$(sudo docker inspect --format="{{.Id}}" mail)
    sudo docker network connect lab-net $id

    #creating email accounts
    sudo $root_path$smtp_server/setup.sh email add student@unicsechub.local [student]
    sudo $root_path$smtp_server/setup.sh email add student1@unicsechub.local [student1]
    sudo $root_path$smtp_server/setup.sh email add student2@unicsechub.local [student2]

    #get lab info
    echo "--------------------------------------------------------------------------------"
    echo "                               Lab Information"
    echo "--------------------------------------------------------------------------------"
    sudo docker inspect lab-net | grep -C3 "IPv4Address"


    #attaching containers
    echo "--------------------------------------------------------------------------------"
    echo "                Opening Container kalilinux with interactive shell"
    echo "--------------------------------------------------------------------------------"
    sudo docker run -it --name kalilinux --network lab-net -v "$root_path"kali_share_folder:/root/kali_share_folder my-kali /bin/bash
}
starting_containers(){
    #starting containers
    echo "--------------------------------------------------------------------------------"
    echo "                              Starting Containers"
    echo "--------------------------------------------------------------------------------"

    #webserver - Ports 22+80
    sudo docker run -d \
        --privileged \
        --name centos1 \
        --network lab-net \
        my-centos1

    #dns - Ports 53+10000
    sudo docker run -d \
        --privileged \
        --name ubuntu-dns \
        --network lab-net \
        --publish 53/tcp \
        --publish 53/udp \
        --publish 10000/tcp \
        sameersbn/bind:9.9.5-20170129

    #flask_ssti - Ports 8000
    cd $root_path$vulhub_path$flask_ssti_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" ssti-web-1)
    #sudo docker network connect lab-net $id

    #activemq_2015 - Ports 8161+61616
    cd $root_path$vulhub_path$activemq_2015_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2015-5254-activemq-1)
    #sudo docker network connect lab-net $id

    #activemq_2016 - Ports 8161+61616
    cd $root_path$vulhub_path$activemq_2016_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2016-3088-activemq-1)
    #sudo docker network connect lab-net $id

    #apero_rce
    cd $root_path$vulhub_path$apero_rce_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" 41-rce-web-1)
    #sudo docker network connect lab-net $id

    #appweb_CVE-2018-8715
    cd $root_path$vulhub_path$appweb_2018_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2018-8715-web-1)
    #sudo docker network connect lab-net $id

    #aria2_rce
    cd $root_path$vulhub_path$aria2_rce_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" rce-aria2-1)
    #sudo docker network connect lab-net $id

    #bash_shellshock-CVE-2014-6271
    cd $root_path$vulhub_path$bash_shellshock_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2014-6271-web-1)
    #sudo docker network connect lab-net $id

    #coldfusion CVE-2010-2861
    cd $root_path$vulhub_path$coldfusion_2010_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2010-2861-coldfusion-1)
    #sudo docker network connect lab-net $id

    #couchdb cve-2017-12635
    cd $root_path$vulhub_path$couchdb_2017_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2017-12635-couchdb-1)
    #sudo docker network connect lab-net $id

    #oracle cve-2020-9402
    cd $root_path$vulhub_path$oracle_sql_injection_2020_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2020-9402-web-1)
    #sudo docker network connect lab-net $id
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2020-9402-db-1)
    #sudo docker network connect lab-net $id

    #dns zone transfer
    cd $root_path$vulhub_path$dns_zone_transf_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" dns-zone-transfer-dns-1)
    #sudo docker network connect lab-net $id

    #mysql cve-2012-2122
    cd $root_path$vulhub_path$mysql_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2012-2122-mysql-1)
    #sudo docker network connect lab-net $id

    #samba cve-2018-7494
    cd $root_path$vulhub_path$samba_path && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" cve-2017-7494-samba-1)
    #sudo docker network connect lab-net $id

    #proftpd 1.3.5 - mod_copy RCE
    #docker buildx create --use
    #docker buildx build --platform=linux/amd64,linux/arm64 .
    sudo docker run -d \
        --privileged \
        --name proftpd_1_3_5 \
        --network lab-net \
        --publish 21/tcp \
        --publish 80/tcp \
        proftp

    #ftp-anon
    sudo docker run -d \
        --privileged \
        --name anon-ftp \
        --network lab-net \
        --publish 20-21/tcp \
        --publish 65500-65515/tcp \
        --volume "$root_path"ftp-anon/mount_partition:/var/ftp:ro \
        docker-anon-ftp
    
    #openssh
    cd $root_path$openssh_server && sudo docker compose up -d
    #id=$(sudo docker inspect --format="{{.Id}}" openssh-server)
    #sudo docker network connect lab-net $id

    #smtp-postfix
    sudo docker run -d \
        --privileged \
        --network lab-net \
        --publish 25/tcp \
        --name postfix -P \
        -e SMTP_SERVER=smpt.uni_sec_hub.local \
        -e SMTP_USERNAME=student@uni_sec_hub.local \
        -e SMTP_PASSWORD=student -e SERVER_HOSTNAME=helpdesk.uni_sec_hub.local \
        juanluisbaptiste/postfix:latest

    #get lab info
    echo "--------------------------------------------------------------------------------"
    echo "                               Lab Information"
    echo "--------------------------------------------------------------------------------"
    sudo docker inspect lab-net | grep -C3 "IPv4Address"

    #attaching containers
    echo "--------------------------------------------------------------------------------"
    echo "                Opening Container kalilinux with interactive shell"
    echo "--------------------------------------------------------------------------------"
    sudo docker run -it --name kalilinux --network lab-net -v "$root_path"kali_share_folder:/root/kali_share_folder my-kali /bin/bash

}

clear_prvious_run(){
    #clear previous runs
    echo "--------------------------------------------------------------------------------"
    echo "                              Cleaning Up After Run"
    echo "--------------------------------------------------------------------------------"
    sudo docker stop $(sudo docker ps -aq)
    sudo docker rm $(sudo docker ps -aq)
    if (( $number_of_images > $max_number_of_images )); then
        echo "Maximum number of image found. Clearing OS"
        sudo docker rmi $(sudo docker images -q)
    else
        echo "Number of allowed images $number_of_images/$max_number_of_images"
    fi
}

clean_up_everything(){
    echo "--------------------------------------------------------------------------------"
    echo "                              Cleaning Up Everything"
    echo "--------------------------------------------------------------------------------"
    sudo docker image prune -a -f
    sudo docker volume prune -f
    sudo docker system prune --volumes
    sudo docker stop $(sudo docker ps -aq)
    sudo docker rm $(sudo docker ps -aq)
    sudo docker rmi $(sudo docker images -q)
}

dvwa(){
    echo "--------------------------------------------------------------------------------"
    echo "                    Downloading the latest DVWA and running it"
    echo "--------------------------------------------------------------------------------"
    if (( "$_architecture" == "arm" )); then
        sudo docker run --rm -it -p 80:80 petechua/docker-vulnerable-dvwa:1.0
    else
        sudo docker run --rm -it -p 80:80 vulnerables/web-dvwa
    fi
}

option_1(){
    clean_up_everything
    option_2
}

option_2(){
    start_services
    set_variables
    clear_previous_runs
    build_images
    create_interfaces
    starting_containers
    clear_prvious_run
}

option_3(){
    start_services
    set_variables
    clear_previous_runs
    dvwa
    clear_prvious_run
}

option_4(){
    start_services
    set_variables
    clear_previous_runs
    build_images
    create_interfaces
    starting_smtp_env
    clear_prvious_run
}

option_5(){
    clean_up_everything
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
        echo "    	0  -  Exit"
        echo "    	1  -  Rebuild Unic Security Hub and then Run it"
        echo "    	2  -  Start the lab with existing builds"
        echo "    	3  -  Start Vulnerable Web Application - DVWA"
        echo "    	4  -  Start a fully functional Email Server"
        echo "    	5  -  Cleanup Everything"
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

menu
