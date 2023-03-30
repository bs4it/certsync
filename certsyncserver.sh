#!/bin/bash

domains="bs4it.com.br"

for domain in $domains;
do
  src_sha256=$(sha256sum /etc/letsencrypt/live/$domain/privkey.pem | awk '{print $1}')
  tgt_sha256=$(sha256sum /home/certsync/certs/$domain/privkey.pem | awk '{print $1}')
  if ! [ $tgt_sha256 == $src_sha256 ]; then
    echo "Cert has changed."
    cp /etc/letsencrypt/live/$domain/privkey.pem /home/certsync/certs/$domain/privkey.pem
    cp /etc/letsencrypt/live/$domain/fullchain.pem /home/certsync/certs/$domain/fullchain.pem
    sha256sum /home/certsync/certs/$domain/privkey.pem | awk '{print $1}' > /home/certsync/certs/$domain/sha256sum
    chown -R certsync:certsync /home/certsync/certs/$domain/*
  else
    echo "Cert is the same, quitting"
  fi
done