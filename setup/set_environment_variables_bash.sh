#!/bin/bash


sudo echo 'export WORKSPACE=~/quantumsafe' >> $HOME/.bashrc
sudo echo 'export BUILD_DIR=$WORKSPACE/build' >> $HOME/.bashrc
sudo echo 'export OPENSSL_CONF=$BUILD_DIR/ssl/openssl.cnf' >> $HOME/.bashrc
sudo echo 'export OPENSSL_MODULES=$BUILD_DIR/lib' >> $HOME/.bashrc
sudo echo 'alias openssl="$BUILD_DIR/bin/openssl"' >> $HOME/.bashrc

echo "Done!"
echo -e "Now execute the following command to make the changes persistent: source $HOME/.bashrc"