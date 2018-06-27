#!/bin/bash
# setup ssh keys for eclickz.com storm instances
scp root@192.168.1.254:.ssh/authorized_keys ~/.ssh
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
scp ~/.ssh/authorized_keys root@192.168.1.254:.ssh/

wget http://www.g33kinfo.com/scripts/eclickz_sshkeys.sh
chmod +x eclickz_sshkeys.sh
sh eclickz_sshkeys.sh
yes
add pw from db server PatelisKing786
enter
enter
enter
add pw from db server PatelisKing786
rm -f eclickz_sshkeys.sh
