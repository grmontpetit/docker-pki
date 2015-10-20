# docker-pki
This is a dockerfile with a root and intermediate CA.

## Use your own PKI Strings
Don't forget to change the -subj parameter for your (ficticious) organization:
-subj "/C=COUNTRYCODE/ST=YOURSTATE/L=CITY/O=ORGANIZATION/CN=CAHOSTNAME"

Also, you should change the passwords used in
-passout and -passin

## PKI Infra
The docker images is running a root and an intermediate CA server.
