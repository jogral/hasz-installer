#!/bin/bash
######################################
## VARS                             ##
######################################
CWD=$(pwd)
HADOOP_MAJOR_VER="2.7"
HADOOP_MINOR_VER="3"
HADOOP_VER="${HADOOP_MAJOR_VER}.${HADOOP_MINOR_VER}"
RSTUDIO_VER="1.0.44"
SPARK_VER="2.0.1"
ANACONDA3_VER="4.2.0"
ZEPPELIN_VER="0.6.2"

RSTUDIO_FILENAME="rstudio-${RSTUDIO_VER}-amd64.deb"
HADOOP_FILENAME="hadoop-${HADOOP_VER}.tar.gz"
SPARK_FILENAME="spark-${SPARK_VER}-bin-hadoop${HADOOP_MAJOR_VER}.tgz"
ANACONDA3_FILENAME="Anaconda3-${ANACONDA3_VER}-Linux-x86_64.sh"
ZEPPELIN_FILENAME="zeppelin-${ZEPPELIN_VER}-bin-all.tgz"

RSTUDIO_DOWNLOAD_URL="https://download1.rstudio.org/${RSTUDIO_FILENAME}"
HADOOP_DOWNLOAD_URL="http://mirrors.ibiblio.org/apache/hadoop/common/hadoop-${HADOOP_VER}/${HADOOP_FILENAME}"
SPARK_DOWNLOAD_URL="http://d3kbcqa49mib13.cloudfront.net/${SPARK_FILENAME}"
ANACONDA3_DOWNLOAD_URL="https://repo.continuum.io/archive/${ANACONDA3_FILENAME}"
ZEPPELIN_DOWNLOAD_URL="http://mirrors.ibiblio.org/apache/zeppelin/zeppelin-${ZEPPELIN_VER}/${ZEPPELIN_FILENAME}"
#-------------------------------------

######################################
## HELPER ACTIONS                   ##
######################################
function set_hadoop_envvars() {
echo """
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')

# Hadoop Environmental Variables
export HADOOP_HOME=\"/usr/local/share/hadoop\"
export HADOOP_MAPRED_HOME=\"\$HADOOP_HOME\"
export HADOOP_COMMON_HOME=\"\$HADOOP_HOME\"
export HADOOP_HDFS_HOME=\"\$HADOOP_HOME\"
export YARN_HOME=\"\$HADOOP_HOME\"
export HADOOP_CONF_DIR=\"\$HADOOP_HOME/etc/hadoop\"
export YARN_CONF_DIR=\"\$HADOOP_HOME/etc/hadoop\"
export HADOOP_COMMON_LIB_NATIVE_DIR=\"\$HADOOP_HOME/lib/native\"
export HADOOP_OPTS=\"-Djava.library.path=$HADOOP_HOME/lib\"
export PATH=\"\$HADOOP_HOME/bin:\$PATH\"
export PATH=\"\$HADOOP_HOME/sbin:\$PATH\"
"""
}
# 15 lines
function set_spark_envvars() {
echo """
export SPARK_HOME=\"/usr/local/share/spark\"
export PATH=\"\$SPARK_HOME/bin:\$SPARK_HOME/sbin:\$PATH\"
"""
}
# 17 lines
#-------------------------------------
######################################
## INSTALL ACTIONS                  ##
######################################
##### Installing RStudio #############
function install_rstudio() {
if [ ! -f $HOME/Downloads/$RSTUDIO_FILENAME ]; then
	curl -L $RSTUDIO_DOWNLOAD_URL -o $HOME/Downloads/$RSTUDIO_FILENAME
elif ! hash rstudio 2>/dev/null; then
	sudo dpkg -i $HOME/Downloads/$RSTUDIO_FILENAME
fi
}
#-------------------------------------
##### Installing Hadoop ##############
function install_hadoop() {
sudo addgroup hadoop
sudo adduser --ingroup hadoop hduser
# Generate SSH key for Hadoop
sudo su hduser -c "ssh localhost 'exit'"
sudo su hduser -c "ssh-keygen -t rsa -b 4096 -P \"\"; cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys" 

# Set Hadoop env variables
set_hadoop_envvars >> $HOME/.bashrc && source $HOME/.bashrc
set_hadoop_envvars | sudo tee --append /home/hduser/.bashrc
sudo su hduser -c "source /home/hduser/.bashrc; echo JAVA_HOME=${JAVA_HOME}"

if [ ! -f $HOME/Downloads/$HADOOP_FILENAME ]; then
	curl -L $HADOOP_DOWNLOAD_URL -o $HOME/Downloads/$HADOOP_FILENAME
fi

tar xzvf $HADOOP_FILENAME
sudo mv hadoop-2.7.3 /usr/local/share
HADOOP_PATH="/usr/local/share/hadoop-2.7.3"
cd /usr/local/share && sudo ln -s $HADOOP_PATH hadoop && cd $HOME/Downloads

if [ ! -d $CWD/scripts/ ]; then
	echo The scripts directory is missing.
	exit 1
else
	$CWD/scripts/configure-hadoop.sh $HADOOP_PATH
fi

sudo chown -R hduser:hadoop $HADOOP_PATH
sudo su hduser -c "${HADOOP_PATH}/bin/hdfs namenode -format"
sudo su hduser -c "${HADOOP_PATH}/sbin/start-dfs.sh; jps; ${HADOOP_PATH}/sbin/start-yarn.sh"
}
#-------------------------------------
##### Install Spark ##################
function install_spark() {
SPARK_PATH="/usr/local/share/spark-${SPARK_VER}-bin-hadoop${HADOOP_MAJOR_VER}"
set_spark_envvars >> $HOME/.bashrc ; source $HOME/.bashrc
sudo addgroup analysts
sudo usermod -a -G analysts $(whoami)
if [ ! -f $HOME/Downloads/$SPARK_FILENAME ]; then
	curl -L $SPARK_DOWNLOAD_URL -o $HOME/Downloads/$SPARK_FILENAME
fi
tar xzvf $HOME/Downloads/$SPARK_FILENAME
sudo mv spark-$SPARK_VER-bin-hadoop$HADOOP_MAJOR_VER /usr/local/share; cd /usr/local/share && sudo ln -s $SPARK_PATH spark && cd $HOME/Downloads; sudo chown -R $(whoami):analysts $SPARK_PATH
sudo cp $SPARK_PATH/conf/spark-env.sh.template $SPARK_PATH/conf/spark-env.sh
echo """
JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')
SPARK_MASTER_IP=10.0.2.15
SPARK_WORKER_MEMORY=3g
""" | sudo tee --append $SPARK_PATH/conf/spark-env.sh
}
#-------------------------------------
##### Installing Anaconda ############
function install_anaconda() {
if [ ! -f $HOME/Downloads/$ANACONDA3_FILENAME ]; then
	curl -L $ANACONDA3_DOWNLOAD_URL -o $HOME/Downloads/$ANACONDA3_FILENAME
fi
bash $ANACONDA3_FILENAME
source $HOME/.bashrc
}
#-------------------------------------
##### Installing Apache Zeppelin #####
function install_zeppelin() {
sudo adduser --system --ingroup analysts zeppelin
if [ ! -f $HOME/Downloads/$ZEPPELIN_FILENAME ]; then
	curl -L $ZEPPELIN_DOWNLOAD_URL -o $HOME/Downloads/$ZEPPELIN_FILENAME
fi
tar xzvf $HOME/Downloads/$ZEPPELIN_FILENAME
sudo mv zeppelin-$ZEPPELIN_VER-bin-all /usr/local && sudo ln -s zeppelin-$ZEPPELIN_VER-bin-all zeppelin
sudo chown -R zeppelin:analysts /usr/local/share/zeppelin
echo """
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
""" | sudo tee /etc/init/zeppelin.conf
sudo service zeppelin start
}
#-------------------------------------
######################################
## SCRIPT                           ##
######################################

#if [ "$EUID" -ne 0 ]; then
#	echo You need sudo privileges to run this.
#	exit 1
#else

cd $HOME/Downloads

##### Get all the packages ###########
sudo add-apt-repository -y ppa:ubuntu-elisp
sudo apt-get -y update
sudo apt-get -y install emacs-snapshot\
			default-jdk\
			ssh\
			ssh-askpass\
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

##### Checking stuff #################
java -version; scala -version

##### Install ########################
install_rstudio
install_hadoop
install_spark
install_anaconda
install_zeppelin

##### Cleanup ########################
rm hadoop-2.7.3.tar.gz rstudio-1.0.44-amd64.deb spark-2.0.1-bin-hadoop2.7.tgz Anaconda3-4.2.0-Linux-x86_64.sh zeppelin-0.6.2-bin-all.tgz
cd $CWD

exit 0

#fi
#-------------------------------------
