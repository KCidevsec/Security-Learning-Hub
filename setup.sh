#script to be run only once to set up your ubuntu installation

sudo apt update && sudo apt upgrade -y
sudo apt install net-tools

sudo apt -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt update

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

sudo apt -y install docker-ce docker-ce-cli containerd.io

sudo apt -y install python3 python3-pip

sudo apt -y install docker-compose

sudo apt -y install gparted