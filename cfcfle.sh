#!/bin/bash

if [ -z "$1" ]
  then
    echo -e "\n\n"
    echo "sh cfcfle.sh myawesomedomain.dev dockerport "
    echo -e "\n"
    exit;
fi


awesomedomain=$1
dockerport=$2

## cert info
CAfilename=limonazzo
bitsStrong=8192
CountryName=MX
StateOrProvinceName=Mexico
LocalityName=Mexico
OrganizationName=Limonazzo.com
OrganizationalUnitName=Limonazzo.com
CommonName=Limonazzo.com
EmailAddress=i@limonazzo.com

if [ ! -d "sslcache" ]; then
  mkdir sslcache
fi

cd sslcache

if [ ! -f $CAfilename.pem ]; then

    ## generating a root certificate
    openssl genrsa -des3 -out $CAfilename.key $bitsStrong
    openssl req -x509 \
    -new -nodes \
    -key $CAfilename.key \
    -sha256 -days 3650 \
    -out $CAfilename.pem \
    -subj "/C=$CountryName/ST=$StateOrProvinceName/L=$LocalityName/O=$OrganizationName/OU=$OrganizationalUnitName/CN=$CommonName"

fi


## generate private key
openssl genrsa -out $awesomedomain.key $bitsStrong

## generate a certificate signing Request for $awesomedomain
openssl req -new \
  -key $awesomedomain.key \
  -out $awesomedomain.csr \
  -subj "/C=$CountryName/ST=$StateOrProvinceName/L=$LocalityName/O=$OrganizationName/OU=$OrganizationalUnitName/CN=$CommonName"

OUT=$awesomedomain.ext
cat <<EOF >$OUT
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $awesomedomain
EOF

## create DA SIGNED CERTIFICATE
openssl x509 -req -in $awesomedomain.csr \
  -CA $CAfilename.pem \
  -CAkey $CAfilename.key \
  -CAcreateserial \
  -out $awesomedomain.crt \
  -days 3650 \
  -sha256 \
  -extfile $awesomedomain.ext

mkdir $awesomedomain
mv $awesomedomain.* $awesomedomain/ 

cd /etc/nginx/

if [ ! -d "ssl" ]; then
  mkdir ssl
fi

cp sslcache/$awesomedomain/$awesomedomain.crt /etc/nginx/ssl/$awesomedomain.crt 
cp sslcache/$awesomedomain/$awesomedomain.key /etc/nginx/ssl/$awesomedomain.key

NGINXDOMAIN=/etc/nginx/sites-available/$awesomedomain
cat <<EOF >$NGINXDOMAIN
server {
    listen          443;
    ssl             on;
    ssl_certificate /etc/nginx/ssl/$awesomedomain.crt;
    ssl_certificate_key /etc/nginx/ssl/$awesomedomain.key; 
    server_name     $awesomedomain;

    location / {
        proxy_pass         https://127.0.0.1:$dockerport;
        proxy_redirect     off;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Host \$server_name;
    }

    add_header Last-Modified \$date_gmt;
    add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
    if_modified_since off;
    expires off;
    etag off;
}
EOF

cd /etc/nginx/sites-enabled 
ln -s ../sites-available/$awesomedomain .

NOW=$(date +%Y-%m-%d-%H.%M.%S)
cp /etc/hosts /etc/hosts_backup_$NOW
sed -i  "1s/^/127.0.0.1    ${awesomedomain}\n/" /etc/hosts

#service nginx reload

echo "done :), import  /etc/nginx/sslcache/$CAfilename.pem  and go to  https://$awesomedomain/" 