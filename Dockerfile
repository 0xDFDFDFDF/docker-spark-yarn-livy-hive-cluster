FROM ubuntu:16.04


USER root 

RUN apt-get update && apt-get -y dist-upgrade && apt-get install -y openssh-server default-jdk wget scala
RUN  apt-get -y update
RUN  apt-get -y install zip 
RUN  apt-get -y install vim
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

RUN ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -P "" \
    && cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

RUN wget -O /hadoop.tar.gz -q http://archive.apache.org/dist/hadoop/core/hadoop-2.7.3/hadoop-2.7.3.tar.gz \
        && tar xfz hadoop.tar.gz \
        && mv /hadoop-2.7.3 /usr/local/hadoop \
        && rm /hadoop.tar.gz

RUN wget -O /spark.tgz -q http://archive.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz \
        && tar xfz spark.tgz \
        && ls -lah \
        && mv /spark-2.4.4-bin-hadoop2.7 /usr/local/spark \
        && rm /spark.tgz

RUN wget -O /livy.zip -q http://ftp.man.poznan.pl/apache/incubator/livy/0.6.0-incubating/apache-livy-0.6.0-incubating-bin.zip \
        &&  unzip livy.zip \
        && mv /apache-livy-0.6.0-incubating-bin /usr/local/livy \
        && rm livy.zip

RUN wget -O /hive.tar.gz -q http://archive.apache.org/dist/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz \
        && tar zxf hive.tar.gz \
        && mv /apache-hive-1.2.1-bin /usr/local/hive \
        && rm /hive.tar.gz

ENV HADOOP_HOME=/usr/local/hadoop
ENV SPARK_HOME=/usr/local/spark
ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/
ENV LIVY_HOME=/usr/local/livy
ENV HIVE_HOME=/usr/local/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME:sbin:$HIVE_HOME/bin

RUN mkdir -p $HADOOP_HOME/hdfs/namenode \
        && mkdir -p $HADOOP_HOME/hdfs/datanode


COPY config/ /tmp/
RUN mv /tmp/ssh_config $HOME/.ssh/config \
    && mv /tmp/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
    && mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml \
    && mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml \
    && mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml.template \
    && cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml \
    && mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml \
    && cp /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves \
    && mv /tmp/slaves $SPARK_HOME/conf/slaves \
    && mv /tmp/spark/spark-env.sh $SPARK_HOME/conf/spark-env.sh \
    && mv /tmp/spark/log4j.properties $SPARK_HOME/conf/log4j.properties \
    && mv /tmp/spark/spark.defaults.conf $SPARK_HOME/conf/spark.defaults.conf \
    && mv /tmp/livy/livy.conf $LIVY_HOME/conf/livy.conf \
    && mv /tmp/hive/hive-env.sh $HIVE_CONF_DIR/ \
    && mv /tmp/hive/hive-site.xml $HIVE_CONF_DIR/ \
    && mv /tmp/hive/hive-init.sh $HIVE_HOME/ \
    && cp $HIVE_CONF_DIR/hive-site.xml $SPARK_HOME/conf/hive-site.xml \
    && cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml $SPARK_HOME/conf/hdfs-site.xml \
    && cp $HADOOP_HOME/etc/hadoop/core-site.xml $SPARK_HOME/conf/hdfs-core.xml

ADD scripts/spark-services.sh $HADOOP_HOME/spark-services.sh

RUN chmod 744 -R $HADOOP_HOME

RUN $HADOOP_HOME/bin/hdfs namenode -format

RUN apt-get update
RUN apt-get -y install python3-pip
RUN pip3 install --upgrade pip
RUN pip3 install -r /tmp/python/requirements.txt

EXPOSE 50010 50020 50070 50075 50090 8020 9000
EXPOSE 10020 19888
EXPOSE 8030 8031 8032 8033 8040 8042 8088
EXPOSE 49707 2122 7001 7002 7003 7004 7005 7006 7007 8888 9000
EXPOSE 3000-3010

ENTRYPOINT service ssh start; cd $SPARK_HOME; bash


