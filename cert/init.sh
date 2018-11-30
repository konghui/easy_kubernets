#!/bin/bash
source ../config
#K8S_SERVICE_IP=10.10.0.1


rm -rf admin apiserver ca node etcd

#create ca
mkdir -p ca
openssl genrsa -out ca/ca-key.pem 2048
openssl req -x509 -new -nodes -key ca/ca-key.pem -days 10000 -out ca/ca.pem -subj "/CN=kube-ca"

#create apiserver certificate
ROOT=apiserver
mkdir -p $ROOT
sed -e "s/{K8S_SERVICE_IP}/$K8S_SERVICE_IP/" -e "s/{MASTER_IPV4}/$MASTER_IPV4/" conf/openssl_apiserver.cnf > $ROOT/openssl_apiserver.cnf
openssl genrsa -out $ROOT/apiserver-key.pem 2048
openssl req -new -key $ROOT/apiserver-key.pem -out $ROOT/apiserver.csr -subj "/CN=kube-apiserver" -config $ROOT/openssl_apiserver.cnf
openssl x509 -req -in $ROOT/apiserver.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out $ROOT/apiserver.pem -days 365 -extensions v3_req -extfile $ROOT/openssl_apiserver.cnf

# create operate certificate
ROOT=admin
mkdir -p $ROOT
openssl genrsa -out $ROOT/admin-key.pem 2048
openssl req -new -key $ROOT/admin-key.pem -out $ROOT/admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in $ROOT/admin.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out $ROOT/admin.pem -days 365


# create node certificate
ROOT=node
mkdir -p $ROOT
sed "s/{WORKER_IPV4}/$WORKER_IPV4/" conf/openssl_worker.cnf > $ROOT/openssl_worker.cnf
openssl genrsa -out $ROOT/worker-key.pem 2048
openssl req -new -key $ROOT/worker-key.pem -out $ROOT/worker.csr -subj "/CN=worker-key" -config $ROOT/openssl_worker.cnf
openssl x509 -req -in $ROOT/worker.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out $ROOT/worker.pem -days 365 -extensions v3_req -extfile $ROOT/openssl_worker.cnf


# create etcd client certificate
ROOT=etcd
mkdir -p $ROOT
#openssl genrsa -out $ROOT/etcd-key.pem 2048
#openssl req -new -key $ROOT/etcd-key.pem -out $ROOT/etcd.csr -subj "/CN=kube-etcd"
#openssl x509 -req -in $ROOT/etcd.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out $ROOT/etcd.pem -days 365


sed "s/{WORKER_IPV4}/$WORKER_IPV4/" conf/openssl_client.cnf > $ROOT/openssl_client.cnf
openssl genrsa -out $ROOT/etcd-key.pem 2048
openssl req -new -key $ROOT/etcd-key.pem -out $ROOT/etcd.csr -subj "/CN=kube-etcd" -config $ROOT/openssl_client.cnf
openssl x509 -req -in $ROOT/etcd.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out $ROOT/etcd.pem -days 365 -extensions v3_req -extfile $ROOT/openssl_client.cnf

# create etcd peer certificate
ROOT=etcd_peer
mkdir -p $ROOT
sed "s/{WORKER_IPV4}/$WORKER_IPV4/" conf/openssl_etcd.cnf > $ROOT/openssl_etcd.cnf
openssl genrsa -out $ROOT/etcd_peer-key.pem 2048
openssl req -new -key $ROOT/etcd_peer-key.pem -out $ROOT/etcd_peer.csr -subj "/CN=etcd-peer" -config $ROOT/openssl_etcd.cnf
openssl x509 -req -in $ROOT/etcd_peer.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out $ROOT/etcd_peer.pem -days 365 -extensions v3_req -extfile $ROOT/openssl_etcd.cnf
