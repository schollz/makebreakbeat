#!/bin/bash

# clear previous workloads
rm -f /tmp/breaktemp-*
sudo ldconfig
if ! command -v sox &> /dev/null
then
	echo "installing sox"
	sudo apt-get install -y sox
fi

if ! command -v sox &> /dev/null
then
	echo "installing sox from static compiled version"
	cd /tmp && wget https://github.com/schollz/makebreakbeat/releases/download/v0.1.0/sox && chmod +x sox && sudo mv sox /usr/local/bin/
fi

if ! command -v aubioonset &> /dev/null
then
	echo "installing aubio"
	cd /tmp/ && git clone https://github.com/aubio/aubio && cd aubio && sed -i 's/curl -so/curl -k -so/g' scripts/get_waf.sh && ./scripts/get_waf.sh && ./waf configure && ./waf build && sudo ./waf install && cd /tmp && rm -rf aubio
fi

FOLDER=/home/we/.local/share/SuperCollider/Extensions/
FILE=/home/we/.local/share/SuperCollider/Extensions/PortedPlugins/AnalogTape_scsynth.so
if [ -d "$FOLDER" ]; then 
	echo "folder exists" > /dev/null
   if [ -f "$FILE" ]; then 
	   echo "ok" > /dev/null
   else
	   echo "installing PortedPlugins..."
	   cd /tmp && wget https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz && tar -xvzf PortedPlugins.tar.gz && rm PortedPlugins.tar.gz && sudo rsync -avrP PortedPlugins /home/we/.local/share/SuperCollider/Extensions/
   fi
fi
