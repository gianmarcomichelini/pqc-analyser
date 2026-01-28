#!/bin/zsh


sudo echo 'export WORKSPACE=~/quantumsafe' >> /home/kali/.zshrc
sudo echo 'export BUILD_DIR=$WORKSPACE/build' >> /home/kali/.zshrc
sudo echo 'export OPENSSL_CONF=$BUILD_DIR/ssl/openssl.cnf' >> /home/kali/.zshrc
sudo echo 'export OPENSSL_MODULES=$BUILD_DIR/lib' >> /home/kali/.zshrc
sudo echo 'alias openssl="$BUILD_DIR/bin/openssl"' >> /home/kali/.zshrc

echo "Done!"
echo -e "Now execute the following command to make the changes persistent: source /home/kali/.zshrc"