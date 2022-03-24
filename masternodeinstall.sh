#!/bin/bash

PORT=3094
RPCPORT=3095
CONF_DIR=~/.bontecoin

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
if [[ $(lsb_release -d) = *18.04* ]]; then
  COINZIP='https://github.com/bontecoin/BONTE/releases/download/v1.0/bonte_ubuntu18.zip'
fi
if [[ $(lsb_release -d) = *20.04* ]]; then
  COINZIP='https://github.com/bontecoin/BONTE/releases/download/v1.0/bonte_ubuntu20.zip'
fi
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/bontecoin.service
[Unit]
Description=Bontecoin Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/bontecoind
ExecStop=-/usr/local/bin/bontecoin-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable bontecoin.service
  systemctl start bontecoin.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev libboost-all-dev libboost-program-options-dev libminiupnpc-dev libzmq3-dev libprotobuf-dev protobuf-compiler unzip software-properties-common cmake zip screen htop curl -y
  sudo apt-get install software-properties-common -y && sudo add-apt-repository ppa:pivx/pivx -y && sudo apt-get update && sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd
  
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  chmod +x bontecoin*
  rm bontecoin-qt bontecoin-tx *.zip
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget http://bontecoin.com/snapshot.zip
  unzip snapshot.zip
  rm snapshot.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> bontecoin.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> bontecoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> bontecoin.conf_TEMP
  echo "rpcport=$RPCPORT" >> bontecoin.conf_TEMP
  echo "listen=1" >> bontecoin.conf_TEMP
  echo "server=1" >> bontecoin.conf_TEMP
  echo "daemon=1" >> bontecoin.conf_TEMP
  echo "maxconnections=250" >> bontecoin.conf_TEMP
  echo "masternode=1" >> bontecoin.conf_TEMP
  echo "dbcache=100" >> bontecoin.conf_TEMP
  echo "maxorphantx=5" >> bontecoin.conf_TEMP
  echo "" >> bontecoin.conf_TEMP
  echo "port=$PORT" >> bontecoin.conf_TEMP
  echo "externalip=$IP:$PORT" >> bontecoin.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> bontecoin.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> bontecoin.conf_TEMP
  mv bontecoin.conf_TEMP bontecoin.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Bontecoin Service: ${GREEN}systemctl start bontecoin${NC}"
echo -e "Check Bontecoin Status Service: ${GREEN}systemctl status bontecoin${NC}"
echo -e "Stop Bontecoin Service: ${GREEN}systemctl stop bontecoin${NC}"
echo -e "Check Masternode Status: ${GREEN}bontecoin-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Bontecoin Masternode Installation Done${NC}"
exec bash
exit