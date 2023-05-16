FROM ubuntu:14.04

LABEL Author=Kyriakos_Costa 
LABEL Email=kyriakoskosta@gmai.com

ARG DEBIAN_FRONTEND=noninteractive

#php5 dependancies and repo
RUN apt update && \
    apt upgrade -y && \
    apt install -y gnupg2 ca-certificates

RUN apt purge `dpkg -l | grep php| awk '{print $2}' |tr "\n" " "`

#RUN add-apt-repository ppa:ondrej/php
RUN echo "deb https://ppa.launchpadcontent.net/ondrej/php/ubuntu focal main" >> /etc/apt/sources.list
RUN echo "#deb-src https://ppa.launchpadcontent.net/ondrej/php/ubuntu focal main" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4f4ea0aae5267a6c 

# install debian stuff
RUN apt update && \
    apt upgrade -y && \
    apt install -y wget apache2 php5 gcc make nano net-tools && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# configure vuln application
RUN wget ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.5.tar.gz && \
    tar xfz proftpd-1.3.5.tar.gz && \
    cd proftpd-1.3.5 && \
    ./configure --with-modules=mod_copy && \
    make && make install

RUN chmod 777 -R /var/www/html/

EXPOSE 21 80

COPY main.sh /
RUN chmod 777 /main.sh
COPY proftpd_mine.conf /usr/local/etc/

RUN chmod 777 /usr/local/etc/proftpd_mine.conf

ENTRYPOINT ["/main.sh"]
CMD ["default"]