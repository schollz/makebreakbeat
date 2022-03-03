#!/bin/bash

if ! command -v sox &> /dev/null
then
	echo "installing sox"
	sudo apt-get install -y sox
fi

if ! command -v aubioonset &> /dev/null
then
	echo "installing aubio"
	cd /tmp/ && git clone https://github.com/aubio/aubio && cd aubio && sed -i 's/curl -so/curl -k -so/g' scripts/get_waf.sh && ./scripts/get_waf.sh && ./waf configure && ./waf build && sudo ./waf install && cd /tmp && rm -rf aubio
fi
