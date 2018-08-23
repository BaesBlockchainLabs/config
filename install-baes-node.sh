#!/bin/bash
#
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
sudo pip3 install bigchaindb==2.0.0b5
#
#######################################
# Install required tendermint version
#######################################
wget https://github.com/tendermint/tendermint/releases/download/v0.22.8/tendermint_0.22.8_linux_amd64.zip
unzip tendermint_0.22.8_linux_amd64.zip
rm tendermint_0.22.8_linux_amd64.zip
sudo mv tendermint /usr/local/bin
#
######################################
# configure and init bigchaindb
######################################
bigchaindb configure
bigchaindb drop
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
wget https://raw.githubusercontent.com/BaesBlockchainLabs/config/master/config.toml
tendermint init
tendermint unsafe_reset_all
popd
#
######################################
# configure and start monit
######################################
bigchaindb-monit-config
monit -d 1
monit
#