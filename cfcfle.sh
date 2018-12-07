#!/bin/bash

if [ -z "$1" ]
  then
    echo -e "\n\n"
    echo "sh cfcfle.sh myawesomedomain.dev "
    echo -e "\n"
    exit;
fi


awesomedomain=$1

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



echo "================================================================================================================= "
echo "================================================================================================================= "
echo -e "\n"
echo "import:  `pwd`/$CAfilename.pem to your browser  "
echo -e "\n"
echo "configure nginx: ================================================================"
echo -e "\n"
echo "cp `pwd`/$awesomedomain/$awesomedomain.crt /etc/nginx/ssl/$awesomedomain.crt "
echo "cp `pwd`/$awesomedomain/$awesomedomain.key /etc/nginx/ssl/$awesomedomain.key "
echo -e "\n"
echo "server {"
echo "    listen 443;"
echo "    ssl on;"
echo "    ssl_certificate /etc/nginx/ssl/$awesomedomain.crt; "
echo "    ssl_certificate_key /etc/nginx/ssl/$awesomedomain.key;"
echo "    server_name $awesomedomain;"
echo "    location / { "
echo "        ... "
echo "    }"
echo "}"
echo -e "\n"
echo "configure apache: ================================================================"
echo -e "\n"
echo "cp `pwd`/$awesomedomain/$awesomedomain.crt /etc/apache2/ssl/$awesomedomain.crt "
echo "cp `pwd`/$awesomedomain/$awesomedomain.key /etc/apache2/ssl/$awesomedomain.key "
echo -e "\n"
echo "    SSLEngine on"
echo "    SSLCertificateFile	/etc/apache2/ssl/$awesomedomain.crt "
echo "    SSLCertificateKeyFile /etc/apache2/ssl/$awesomedomain.key "
echo -e "\n"
echo "================================================================================================================= "
echo "================================================================================================================= "


