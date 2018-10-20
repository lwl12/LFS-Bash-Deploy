#!/bin/bash

if (( EUID != 0 )); then
   echo "You must be root to do this." 1>&2
   exit 100
fi

if [ $1 = '' ]
  then
    echo "You must specify a hostname."
    exit
fi

#Hostname
echo "Setting up hostname $1...\n"
hostname "ecs-$1.cn2.network"
echo $1 > /etc/hostname
echo "127.0.1.1 $1" >> /etc/hosts
echo "Hostname OK!\n"

#BBR
echo "Setting up BBR...\n"
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1
echo "BBR OK!\n"

#LOGIN MOTD
echo "Setting up MOTD...\n"
cat > /etc/update-motd.d/00-header <<EOL
printf  "Welcome to LWL $1 Server!\n"
curl "https://api.lwl12.com/hitokoto/main/get" -m 2
printf "\n---------------------"
EOL
rm /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/80-esm /etc/update-motd.d/95-hwe-eol
echo "MOTD OK!\n"

#Docker
echo "Setting up Docker...\n"
sudo apt-get remove docker docker-engine docker.io
sudo apt-get update
sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce
sudo docker version
echo '{ "registry-mirrors": ["https://registry.docker-cn.com"] }' > /etc/docker/daemon.json
sudo docker run hello-world
echo "Don't forget to set newest docker compose version!"
sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
echo "Docker OK!\n"

#LFS
echo "Setting up LFS...\n"
apt-get install git -y
cd /opt
git clone https://github.com/lwl12/LFS-Docker-Compose.git /opt
echo "TZ=Asia/Shanghai\nHostname=$1" > /opt/LFS-Docker-Compose/.env
echo "LFS OK!\n"

#User
echo "Setting up user...\n"
useradd lwl12
chage -d 0 lwl12
mkdir /home/lwl12/.ssh/ -p
echo "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGFJYtyrc/bvohe5f0mTSSwlDoZj+i5/v9NhBz7ILGlEh2pe/DtmeSeiFFPewLBLFc40nG/P+OsI/K8y+5ePEUHJgBWWLfI80CVUwz9FmnChEFdi2lJlFVpgMP2R4muNhvL8HCFRKLMZW215YpyqIA5J+Wi4+Xr5ey/K5V4Cmj+sTEXPQ== lwl_ecdsa_521" > /home/lwl12/.ssh/authorized_keys
chown lwl12:lwl12 /home/lwl12/.ssh -R
chmod 644 /home/lwl12/.ssh/authorized_keys
echo "lwl12  ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "User OK!\n"

#SSH
echo "Setting up SSH...\n"
if [ -z "`grep ^Port /etc/ssh/sshd_config`"]; then
    sed -i "s@^#Port.*@&\nPort 36015@" /etc/ssh/sshd_config
  elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
    sed -i "s@^Port.*@Port 36015@" /etc/ssh/sshd_config
  fi
fi
sed -i "s@^#PasswordAuthentication.*@&\nPasswordAuthentication no@" /etc/ssh/sshd_config
echo "SSH OK!\n"

#ZSH
echo "Setting up ZSH...\n"
apt-get install zsh -y
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo "ZSH OK!\n"


echo "INIT OK!\nDON'T FORGET DEL DEFAULT USER!"
exit 0;
