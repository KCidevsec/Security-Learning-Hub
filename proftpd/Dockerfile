FROM debian:jessie

LABEL Author=Kyriakos_Costa 
LABEL Email=kyriakoskosta@gmai.com

# install debian stuff
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget apache2 gcc php5 make nano net-tools\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

#RUN add-apt-repository ppa:ondrej/php && \
#    apt-get update && \
#    apt-get install php5

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