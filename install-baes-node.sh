#!/bin/bash

####################################################
# NODE_TYPE can be "CLI"  for client node
#                  "BOOT" for boot node
#                  "VAL"  for validator node
####################################################
NODE_TYPE="CLI" 
#
TM_VERSION="0.22.8"
BDB_VERSION="2.0.0b7"
TM_FILE=tendermint_"$TM_VERSION"_linux_amd64.zip

#################
# ATENCION:
# Es posible que la orden 'tendermint init', hacia el final del script, dé este error:
#   Error reading PrivValidator from /home/*/.tendermint/config/priv_validator.json: unrecognized concrete type name AC26791624DE60
# Es debido a que si el fichero (que contiene la clave del nodo como validador) se generó con una versión antigua de tendermint, hay que actualizar
# el formato del campo pub_key.type, cambiando "AC26791624DE60" por "tendermint/PubKeyEd25519". Esto antes de ejecutar el script.
################
#
######################################
#
######################################
#
OS_VENDOR=`lsb_release -s -i`
OS_VERSION=`lsb_release -s -r`

if [ "$OS_VENDOR" != "Ubuntu" ]; then
  echo "You need a modern ubuntu distribution ( >= 18.04) to install the node"
  exit
fi

case $OS_VERSION in
18.04)
    echo "Version of ubuntu is 18.04 ok"
    ;;
*)
    echo "Version of Ubuntu $OS_VERSION is not tested"
    exit
esac

echo "Vendor: $OS_VENDOR  Release: $OS_VERSION"
######################################
# OS update
######################################
sudo apt update
sudo apt full-upgrade
#
######################################
# Install system dependencies
######################################
sudo apt install -y python3-pip libssl-dev wget unzip mongodb monit jq
#
#######################################
# Uninstall previous BigchainDB and
# tendermint versions (if exist)
#######################################
sudo pip3 uninstall bigchaindb
sudo rm -f /usr/local/bin/tendermint
#
#######################################
# Install required bigchaindb version
#######################################
sudo pip3 install bigchaindb==$BDB_VERSION
#
#######################################
# Install required tendermint version
#######################################

if [ ! -f $TM_FILE ]; then
    echo "Downloading tendermint!"
    wget https://github.com/tendermint/tendermint/releases/download/v$TM_VERSION/$TM_FILE

fi

unzip $TM_FILE
sudo mv tendermint /usr/local/bin
#
######################################
# configure and init bigchaindb
######################################
#
if [ ! -f $HOME/.bigchaindb ]; then
    echo "Configuring BigchainDB!"
    bigchaindb configure
fi


bigchaindb drop
bigchaindb init
#
######################################
# Download tendermint configuration
# and genesis from repo and reset
# to genesis state
######################################



mkdir -p  ~/.tendermint/config
pushd ~/.tendermint/config
rm -f genesis.json
rm -f config.toml
wget https://raw.githubusercontent.com/BaesBlockchainLabs/config/master/genesis.json
wget https://raw.githubusercontent.com/BaesBlockchainLabs/config/master/config-template.toml
tendermint init
tendermint unsafe_reset_all
MONIKER=$('hostname')
echo $MONIKER

sed -e s/__MONIKER__/"$NODE_TYPE"_"$MONIKER"/g config-template.toml > config.toml
rm config-template.toml
popd

#
######################################
# configure and start monit
######################################
bigchaindb-monit-config
monit -d 1
monit
#
