FROM openjdk:8-jre
MAINTAINER Singularities

# Version
ENV HADOOP_VERSION=2.8.3

# Set home
ENV HADOOP_HOME=/usr/local/hadoop-$HADOOP_VERSION

# Install dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
    -yq --no-install-recommends netcat procps \
  && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install Hadoop
RUN mkdir -p "${HADOOP_HOME}" \
  && export ARCHIVE=hadoop-$HADOOP_VERSION.tar.gz \
  && export DOWNLOAD_PATH=apache/hadoop/common/hadoop-$HADOOP_VERSION/$ARCHIVE \
  && curl -sSL https://mirrors.ocf.berkeley.edu/$DOWNLOAD_PATH | \
    tar -xz -C $HADOOP_HOME --strip-components 1 \
  && rm -rf $ARCHIVE

# HDFS volume
VOLUME /opt/hdfs

# Set paths
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop \
  HADOOP_LIBEXEC_DIR=$HADOOP_HOME/libexec \
  PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Copy and fix configuration files
COPY /conf/*.xml $HADOOP_CONF_DIR/
RUN sed -i.bak "s/hadoop-daemons.sh/hadoop-daemon.sh/g" \
    $HADOOP_HOME/sbin/start-dfs.sh \
  && rm -f $HADOOP_HOME/sbin/start-dfs.sh.bak \
  && sed -i.bak "s/hadoop-daemons.sh/hadoop-daemon.sh/g" \
    $HADOOP_HOME/sbin/stop-dfs.sh \
  && rm -f $HADOOP_HOME/sbin/stop-dfs.sh.bak

# HDFS
EXPOSE 8020 9000 14000 50010 50020 50070 50075 50090 50470 50475

# MapReduce
EXPOSE 10020 13562	19888

# Copy start scripts
COPY start-hadoop /opt/util/bin/start-hadoop
COPY start-hadoop-namenode /opt/util/bin/start-hadoop-namenode
COPY start-hadoop-datanode /opt/util/bin/start-hadoop-datanode
ENV PATH=$PATH:/opt/util/bin

# Fix environment for other users
RUN echo "export HADOOP_HOME=$HADOOP_HOME" > /etc/bash.bashrc.tmp \
  && echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:/opt/util/bin'>> /etc/bash.bashrc.tmp \
  && cat /etc/bash.bashrc >> /etc/bash.bashrc.tmp \
  && mv -f /etc/bash.bashrc.tmp /etc/bash.bashrc
