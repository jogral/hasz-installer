#!/bin/bash
######################################
## VARS                             ##
######################################

HADOOP_PATH="$1"
JAVA_PATH="$(readlink -f /usr/bin/java | sed 's:bin/java::')"

#-------------------------------------

######################################
## HELPER ACTIONS                   ##
######################################

function create_core-site() {
echo """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
	<!-- file system properties -->
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://localhost:50070/</value>
	</property>
</configuration>
"""
}

function create_hdfs-site() {
echo """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
	<property>
		<name>dfs.replication</name>
		<value>1</value>
	</property>
	<property>
		<name>dfs.namenode.name.dir</name>
		<value>\${HADOOP_HOME}/hdfs/namenode</value>
	</property>
	<property>
		<name>dfs.namenode.name.dir.restore</name>
		<value>true</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>\${HADOOP_HOME}/hdfs/datanode</value>
	</property>
	<property>
		<name>dfs.namenode.checkpoint.dir</name>
		<value>\${HADOOP_HOME}/hdfs/secondarynamenode</value>
	</property>
	<property>
		<name>dfs.permissions</name>
		<value>true</value>
	</property>
</configuration>
"""
}
function create_mapred-site() {
echo """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
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
"""
}

function create_yarn-site() {
echo """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
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
"""
}
#-------------------------------------

######################################
## SCRIPT                           ##
######################################

if [ ! -d $HADOOP_PATH ]; then
	echo You must specify a directory.
	exit 1
else
	create_core-site | sudo tee $HADOOP_PATH/etc/hadoop/core-site.xml
	create_hdfs-site | sudo tee $HADOOP_PATH/etc/hadoop/hdfs-site.xml
	create_mapred-site | sudo tee $HADOOP_PATH/etc/hadoop/mapred-site.xml
	create_yarn-site | sudo tee $HADOOP_PATH/etc/hadoop/yarn-site.xml
	sudo sed -i -e "s:\${JAVA_HOME}:${JAVA_PATH}:g" $HADOOP_PATH/etc/hadoop/hadoop-env.sh
fi
#-------------------------------------
