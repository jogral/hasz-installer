#!/bin/bash

function set_hadoop_envvars() {
echo """
export JAVA_HOME=$(readlink -f /usr/bin/java | sed \"s:bin/java::\")

# Hadoop Environmental Variables
export HADOOP_HOME=\"/usr/local/share/hadoop\"
export HADOOP_MAPRED_HOME=\"$HADOOP_HOME\"
export HADOOP_COMMON_HOME=\"$HADOOP_HOME\"
export HADOOP_HDFS_HOME=\"$HADOOP_HOME\"
export YARN_HOME=\"$HADOOP_HOME\"
export HADOOP_CONF_DIR=\"$HADOOP_HOME/etc/hadoop\"
export YARN_CONF_DIR=\"$HADOOP_HOME/etc/hadoop\"
export HADOOP_COMMON_LIB_NATIVE_DIR=\"$HADOOP_HOME/lib/native\"
export HADOOP_OPTS=\"-Djava.library.path=$HADOOP_HOME/lib\"
export PATH=\"$HADOOP_HOME/bin:$PATH\"
export PATH=\"$HADOOP_HOME/sbin:$PATH\"
"""
}
function set_spark_envvars() {
echo """
export SPARK_HOME=\"/usr/local/share/spark\"
export PATH=\"$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH\"
"""
}

cd $HOME/Downloads

##### Get all the packages for everything #####
sudo add-apt-repository -y ppa:ubuntu-elisp
sudo apt-get -y update
sudo apt-get -y install emacs-snapshot\
			default-jdk\
			ssh\
			git\
			scala\
			nodejs-legacy\
			npm\
			libfontconfig\
			libgstreamer-plugins-base0.10-0\
			libgstreamer0.10-0\
			libjpeg62\
			r-base\
			r-base-dev

##### Checking stuff #####
java -version; scala -version

##### Installing RStudio #####
wget https://download1.rstudio.org/rstudio-1.0.44-amd64.deb
sudo dpkg -i rstudio-1.0.44-amd64.deb

##### Installing Hadoop #####
sudo addgroup hadoop
sudo adduser --ingroup hadoop hduser
sudo su hduser -c "ssh-keygen -t rsa -b 4096 -P \"\"; cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys" 
sudo su hduser -c "ssh localhost; exit"
# Generate SSH key for Hadoop

# Set Hadoop env variables
set_hadoop_envvars >> $HOME/.bashrc && source $HOME/.bashrc
sudo su hduser -c "$(set_hadoop_envvars) >> ~/.bashrc; source ~/.bashrc"

wget http://mirrors.ibiblio.org/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
tar xzvf hadoop-2.7.3.tar.gz
sudo mv hadoop-2.7.3 /usr/local/share
HADOOP_PATH=/usr/local/share/hadoop-2.7.3
cd /usr/local/share && sudo ln -s hadoop $HADOOP_PATH && cd $HOME/Downloads

sudo echo """
<configuration>
	<!-- file system properties -->
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://localhost:50070/</value>
	</property>
</configuration>
""" > $HADOOP_PATH/core-site.xml
sudo echo """
<configuration>
	<property>
		<name>dfs.replication</name>
		<value>1</value>
	</property>
	<property>
		<name>dfs.namenode.name.dir</name>
		<value>${HADOOP_HOME}/hdfs/namenode</value>
	</property>
	<property>
		<name>dfs.namenode.name.dir.restore</name>
		<value>true</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>${HADOOP_HOME}/hdfs/datanode</value>
	</property>
	<property>
		<name>dfs.namenode.checkpoint.dir</name>
		<value>${HADOOP_HOME}/hdfs/secondarynamenode</value>
	</property>
	<property>
		<name>dfs.permissions</name>
		<value>true</value>
	</property>
</configuration>
""" > $HADOOP_PATH/hdfs-site.xml
sudo echo """
<configuration>
	<property>
		<name>mapreduce.cluster.temp.dir</name>
		<value></value>
		<final>true</final>
	</property>
	<property>
		<name>mapreduce.cluster.local.dir</name>
		<value></value>
		<final>true</final>
	</property>
	<property>
		<name>mapreduce.job.maps</name>
		<value>2</value>
	</property>
	<property>
		<name>mapreduce.job.reduces</name>
		<value>1</value>
	</property>
	<property>
		<name>mapreduce.jobtracker.taskscheduler</name>
		<value>org.apache.hadoop.mapred.JobQueueTaskScheduler</value>
	</property>
	<property>
		<name>mapreduce.job.counters.limit</name>
		<value>120</value>
	</property>
</configuration>
""" > $HADOOP_PATH/mapred-site.xml
sudo echo """

<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
	<property>
		<name>yarn.resourcemanager.scheduler.class</name>
		<value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
		<value>org.apache.hadoop.mapred.ShuffleHandler</value>
	</property>
	<property>
		<name>yarn.app.mapreduce.am.staging-dir</name>
		<value>/tmp/hadoop-yarn/staging</value>
	</property>
</configuration>
""" > $HADOOP_PATH/yarn-site.xml
sudo perl -p -i -e 's/\{JAVA_HOME\}/\(readlink -f \/usr\/bin\/java | sed \"s:bin\/java::\"\)/g' /usr/local/share/hadoop/etc/hadoop-env.sh

sudo chown -R hduser:hadoop $HADOOP_PATH

sudo su hduser -c "hdfs namenode -format; start-dfs.sh; jps; start-yarn.sh"

##### Install Spark #####
SPARK_PATH=/usr/local/share/spark-2.0.1-bin-hadoop2.7
set_spark_envvars >> $HOME/.bashrc && source $HOME/.bashrc
sudo addgroup analysts
sudo usermod -a -G analysts $(whoami)
wget http://d3kbcqa49mib13.cloudfront.net/spark-2.0.1-bin-hadoop2.7.tgz
tar xzvf spark-2.0.1-bin-hadoop2.7.tgz
sudo mv spark-2.0.1-bin-hadoop2.7 /usr/local/share; cd /usr/local/share && sudo ln -s spark $SPARK_PATH && cd $HOME/Downloads; sudo chown -R $(whoami):analysts $SPARK_PATH
sudo cp $SPARK_PATH/conf/spark-env.sh.template $SPARK_PATH/conf/spark-env.sh
echo """
JAVA_HOME=$(readlink -f /usr/bin/java | sed \"s:bin/java::\")
SPARK_MASTER_IP=10.0.2.15
SPARK_WORKER_MEMORY=3g
""" >> $SPARK_PATH/conf/spark-env.sh

##### Installing Anaconda #####
wget https://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh | bash

##### Installing Apache Zeppelin
sudo adduser --system --ingroup analysts zeppelin
wget http://mirrors.ibiblio.org/apache/zeppelin/zeppelin-0.6.2/zeppelin-0.6.2-bin-all.tgz
tar xzvf zeppelin-0.6.2-bin-all.tgz
sudo mv zeppelin-0.6.2-bin-all /usr/local && sudo ln -s zeppelin zeppelin-0.6.2-bin-all
sudo chown -R zeppelin:analysts /usr/local/share/zeppelin
sudo echo """
description \"zeppelin\"

start on (local-filesystems and net-device-up IFACE!=lo)
stop on shutdown

# Respawn the process on unexpected termination
respawn

# respawn the job up to 7 times within a 5 second period.
# If the job exceeds these values, it will be stopped and marked as failed.
respawn limit 7 5

# zeppelin was installed in /usr/share/zeppelin in this example
chdir /usr/local/share/zeppelin
exec bin/zeppelin-daemon.sh upstart
""" > /etc/init/zeppelin.conf
sudo service zeppelin start
