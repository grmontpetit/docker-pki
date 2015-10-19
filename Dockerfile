FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install openssl openssh-server -y --force-yes --assume-yes

## Add sshd service to the container
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ADD run.sh /root/run.sh

## Following steps extracted from https://jamielinux.com/docs/openssl-certificate-authority/

## Root CA
RUN mkdir -p /root/ca/certs
RUN mkdir -p /root/ca/crl
RUN mkdir -p /root/ca/newcerts
RUN mkdir -p /root/ca/private
RUN chmod 700 /root/ca/private
RUN touch /root/ca/index.txt
RUN echo 1000 > /root/ca/serial
ADD config/root /root/ca
RUN openssl genrsa -aes256 -out /root/ca/private/ca.key.pem -passout pass:123456 4096
RUN chmod 400 /root/ca/private/ca.key.pem
RUN openssl req -config /root/ca/openssl.cnf -key /root/ca/private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out /root/ca/certs/ca.cert.pem -subj "/C=CA/ST=Quebec/L=Montreal/O=Inocybe/CN=localhost" -passout pass:123456 -passin pass:123456
RUN chmod 444 /root/ca/certs/ca.cert.pem

## Intermediate CA
RUN mkdir /root/ca/intermediate
RUN mkdir -p /root/ca/intermediate/certs
RUN mkdir -p /root/ca/intermediate/crl
RUN mkdir -p /root/ca/intermediate/csr
RUN mkdir -p /root/ca/intermediate/newcerts
RUN mkdir -p /root/ca/intermediate/private
RUN chmod 700 /root/ca/intermediate/private
RUN touch /root/ca/intermediate/index.txt
RUN echo 1000 > /root/ca/intermediate/serial
RUN echo 1000 > /root/ca/intermediate/crlnumber
ADD config/intermediate /root/ca/intermediate
RUN openssl genrsa -aes256 -out /root/ca/intermediate/private/intermediate.key.pem -passout pass:123456 4096
RUN chmod 400 /root/ca/intermediate/private/intermediate.key.pem
RUN openssl req -config /root/ca/intermediate/openssl.cnf -new -sha256 -key /root/ca/intermediate/private/intermediate.key.pem -out /root/ca/intermediate/csr/intermediate.csr.pem -subj "/C=CA/ST=Quebec/L=Montreal/O=Inocybe/CN=localhost" -passout pass:123456 -passin pass:123456
# Here we specify the root openssl.cnf config file
RUN openssl ca -config /root/ca/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in /root/ca/intermediate/csr/intermediate.csr.pem -out /root/ca/intermediate/certs/intermediate.cert.pem -passin pass:123456 -batch
RUN chmod 444 /root/ca/intermediate/certs/intermediate.cert.pem

## Create the certificate chain
RUN cat /root/ca/intermediate/certs/intermediate.cert.pem /root/ca/certs/ca.cert.pem > /root/ca/intermediate/certs/ca-chain.cert.pem

## Next steps is the signing of CSR
## I might code an application that listen over a specific port to do it.

## Open Required Ports
EXPOSE 22
## Run a service so the container is always running
CMD /usr/sbin/sshd -D ; /root/run.sh
