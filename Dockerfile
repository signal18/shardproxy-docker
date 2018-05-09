FROM centos:7

RUN groupadd -r mysql && useradd -r -g mysql mysql

COPY mysqld mysql /usr/local/bin/
COPY datadir/ /var/lib/shardproxy/
COPY errmsg.sys /usr/local/mysql/share/

RUN chown -R mysql:mysql /var/lib/shardproxy
RUN yum -y install libaio

VOLUME /var/lib/shardproxy

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3306

CMD ["mysqld", "--datadir=/var/lib/shardproxy", "--user=mysql"]
