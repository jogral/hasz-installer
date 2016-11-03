# Data Science Workbench Installer (dswb-installer)
I had to create an Ubuntu image twice of the tools I wanted to use for the [Data Science Workbench](https://datascienceworkbench.com/), because I couldn't export the original image.
Since setting up Hadoop, Spark, and Zeppelin are sort of a chore, I wrote a quick and dirty script to install. Right now, this has been tested on **Ubuntu 16.04 LTS**. I'll test other distros
when I'm not lazy.

Instructions
------------------------
Well, this one is easy. Simply run:

	git clone https://github.com/makiten/dswb-installer.git
	cd dswb-installer
	./setup.sh

And follow the prompts that will come up, and watch it install.


License
-------------------------
This repo is open source under the MIT License.

TODO
-------------------------
* Thorough testing
* Cleanup on failure
