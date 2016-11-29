# Hadoop-Anaconda-Spark-Zeppelin Installer (hasz-installer)
I had to create an Ubuntu image twice of the tools I wanted to use in the free IBM service [Data Science Workbench](https://datascienceworkbench.com/), because I couldn't export the original image.
As with any offline/non-cloud installation, setting up Hadoop, Spark, and Zeppelin are an automate-able chore, so I wrote a quick and dirty script to install. Right now, this has been tested on **Ubuntu 16.04 LTS**. I'll test other distros
when I'm not lazy.

Instructions
------------------------
Well, this one is easy. Simply run:

	git clone https://github.com/makiten/hasz-installer.git
	cd hasz-installer
	./setup.sh
	sudo reboot

And follow the prompts that will come up, and watch it install.


License
-------------------------
This repo is open source under the MIT License.

TODO
-------------------------
* Thorough testing
* Cleanup on failure
