FROM metabrainz/base-image

RUN apt-get check
RUN apt-get update \
    && apt-get install -y --no-install-suggests --no-install-recommends vsftpd unzip curl wget iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/run/vsftpd/empty
RUN mkdir -p /etc/vsftpd 
RUN mkdir -p /var/ftp 
RUN mv /etc/vsftpd.conf /etc/vsftpd.orig 
RUN mkdir -p /etc/service/vsftpd

ADD vsftpd.sh /etc/service/vsftpd/run

VOLUME ["/var/ftp"]

RUN chmod 777 /etc/service/vsftpd/run
RUN chmod 777 /var/ftp

EXPOSE 20 21
EXPOSE 65500-65515