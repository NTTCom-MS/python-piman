#!/bin/bash

yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2	\
  cowsay

rpm -qa | grep docker-ce > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

  yum install docker-ce -y
fi

if [ ! -f /etc/docker/daemon.json ];
then
  mkdir -p /etc/docker
  cat <<"EOF" > /etc/docker/daemon.json
{
    "icc": false,
    "log-level": "info",
    "iptables": true,
    "live-restore": true,
    "userland-proxy": false,
    "no-new-privileges": true,
    "storage-driver": "overlay2",
    "bip": "169.254.0.1/16"
}
EOF
fi

systemctl status docker > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  systemctl start docker
fi

if [ ! -f /usr/local/bin/docker-compose ];
then
  curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

rpm -qa | grep ius-release > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  yum install  https://centos7.iuscommunity.org/ius-release.rpm -y
fi

rpm -qa | grep git2u > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  yum remove git -y
  yum install git2u -y
fi

rpm -qa | grep python3 > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  yum install python3 python3-pip -y
fi

pip3 install -r requirements.txt

if [ ! -f /usr/local/bin/piman ];
then
  cat <<EOF > /usr/local/bin/piman
#!/bin/bash
python3 /opt/python-piman/piman.py -c /etc/piman/piman.config
EOF
  chmod +x /usr/local/bin/piman
fi

docker info | grep "Storage Driver" | grep "overlay2" >/dev/null 2>&1
if [ "$?" -ne 0 ];
then
  echo "== WARNING: docker's storage driver is not overlay2 (current value: $(docker info | grep "Storage Driver"))"
fi

git --version | awk '{ print $3 }' | grep "^2" >/dev/null 2>&1
if [ "$?" -ne 0 ];
then
  echo "== WARNING: git version is not 2 (current version: $(git --version | awk '{ print $3 }'))"
fi