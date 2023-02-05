FROM kalilinux/kali-rolling:latest
LABEL Author=Kyriakos_Costa 
LABEL Email=kyriakoskosta@gmai.com

RUN 	apt update -y && \
	apt upgrade -y && \
        apt install -y \
	metasploit-framework \
        net-tools \
        nmap \
        iputils-ping \
        openssh-server \
        man \
        ncat \
        python2.7 \
        python3 \
        python3-pip \
        ssh-audit \
        telnet \
        dnsutils

RUN mkdir -p ~/kali_share_folder

RUN pip install requests
