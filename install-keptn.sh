#!/bin/bash
cd ~
# git clone https://github.com/keptn/keptn.git
export DOMAIN=mushroom.home
export PLATFORM=kubernetes
export ISTIO_INSTALL_OPTION=Reuse
cd ~/keptn/installer/scripts
bash ./installKeptn.sh
cd ~
