#!/bin/bash

services="haproxy.service sshd.service"
host="172.24.0.26"
user="certsync"

if ! [ -f /opt/bs4it/certsync/domains.conf ]; then
  echo "File '/opt/bs4it/certsync/domains.conf' not found. Creating it."
  touch /opt/bs4it/certsync/domains.conf
fi
# read domain list from file
read -d $'\x04' domains < /opt/bs4it/certsync/domains.conf

certchanged=0
for domain in $domains;
do
  home=$(ssh $user@$host printenv HOME)
  src_sha256=$(ssh $user@$host cat $home/certs/$domain/sha256sum)
  tgt_sha256=$(sha256sum /etc/ssl/private/$domain/privkey.pem | awk '{print $1}')
  if ! [ $tgt_sha256 == $src_sha256 ]; then
    echo "Cert for $domain has changed."
    certchanged=1
    mkdir -p /etc/ssl/private/$domain/
    scp certsync@$host:$home/certs/$domain/privkey.pem /etc/ssl/private/$domain/privkey.pem
    scp certsync@$host:$home/certs/$domain/fullchain.pem /etc/ssl/private/$domain/fullchain.pem
    chown -R root:root /etc/ssl/private/$domain/*
    cat /etc/ssl/private/$domain/fullchain.pem > /etc/ssl/private/$domain/$domain.pem
    cat /etc/ssl/private/$domain/privkey.pem >> /etc/ssl/private/$domain/$domain.pem
    chmod 644 /etc/ssl/private/$domain/fullchain.pem
    chmod 600 /etc/ssl/private/$domain/privkey.pem /etc/ssl/private/$domain/$domain.pem
  fi
done

if [ $certchanged -eq 1 ]; then
  echo "Restarting Services..."
  for service in $services;
  do
    echo Issuing restart command to $service
    /usr/bin/systemctl restart $service
  done
fi
