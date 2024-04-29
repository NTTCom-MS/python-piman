#!/bin/bash

if VERB_INSTALL="$( which apt-get )" 2> /dev/null; then
 echo "Debian-based"
 $VERB_INSTALL install -y software-properties-common
 VERB_ADD_REPO="$(which add-apt-repository)"  2> /dev/null
 VERB_PACKAGE="$( which dpkg )"  2> /dev/null
 VERB_PACKAGE_LIST_FLAGS="-l"
  elif VERB_INSTALL="$( which yum )" 2> /dev/null; then
 echo "Modern Red Hat-based"
 VERB_PACKAGE="$( which rpm )"  2> /dev/null
 VERB_PACKAGE_LIST_FLAGS="-qa"a
 $VERB_INSTALL install -y yum-utils \
        device-mapper-persistent-data
 $VERB_ADD_REPO="$(which  yum-config-manager)""--add-repo" 2> /dev/null
  else
 echo "Not suported OS." >&2
 exit 1
fi

if [ ! -d /opt/python-piman/.git ];
then
  echo ">> ERROR: /opt/python-piman is not a repository; please clone piman respistory to /opt/python-piman"
  exit 1
fi

cd /opt/python-piman
git pull origin master

$VERB_INSTALL install -y lvm2   \
  cowsay

$VERB_PACKAGE $VERB_PACKAGE_LIST_FLAGS | grep docker-ce > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  $VERB_ADD_REPO \
    https://download.docker.com/linux/centos/docker-ce.repo

  $VERB_INSTALL_PACKAGE install docker-ce -y
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
  systemctl enable docker
  systemctl start docker
fi

if [ ! -f /usr/local/bin/docker-compose ];
then
  curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

#$VERB_PACKAGE $VERB_PACKAGE_LIST_FLAGS | grep ius-release > /dev/null 2>&1
#if [ "$?" -ne 0 ];
#then
#  $VERB_INSTALL_PACKAGE install  https://centos7.iuscommunity.org/ius-release.rpm -y
#fi

#rpm -qa | grep git2u > /dev/null 2>&1
#if [ "$?" -ne 0 ];
#then
#  yum remove git -y
#  yum install git2u -y
#fi

$VERB_PACKAGE $VERB_PACKAGE_LIST_FLAGS  | grep python3 > /dev/null 2>&1
if [ "$?" -ne 0 ];
then
  $VERB_INSTALL install python3 python3-pip -y
fi

if [ ! -f /opt/python-piman/requirements.txt ];
then
  echo ">> ERROR: PIM requirements file NOT FOUND"
fi
pip3 install -r /opt/python-piman/requirements.txt

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

if [ ! -d /etc/piman ];
then
  mkdir -p /etc/piman
  ln -s /opt/python-piman/siteppgen /etc/piman/siteppgen

  cp /opt/python-piman/piman.config-template /etc/piman/piman.config

  cp /opt/python-piman/pfgen.config-template /etc/piman/pfgen.config

  cp /opt/python-piman/hieragen.config-template /etc/piman/hieragen.config

  cp /opt/python-piman/siteppgen.config-template /etc/piman/siteppgen.config
fi
