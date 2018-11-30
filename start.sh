#!/bin/bash
. config

function start_etcd() {
    $ETCD_BINARY \
        --name $ETCD_NODE1_NAME \
        --listen-peer-urls $ETCD_NODE1_LISTEN_URL \
        --initial-advertise-peer-urls $ETCD_NODE1_LISTEN_URL \
        --advertise-client-urls $ETCD_NODE1_CLIENT_URL \
        --listen-client-urls $ETCD_NODE1_CLIENT_URL \
        --initial-cluster-state new \
        --initial-cluster $ETCD_NODE1_NAME=$ETCD_NODE1_LISTEN_URL,$ETCD_NODE2_NAME=$ETCD_NODE2_LISTEN_URL,$ETCD_NODE3_NAME=$ETCD_NODE3_LISTEN_URL \
        --trusted-ca-file $CA_CERT_FILE   \
        --cert-file $ETCD_CERT_FILE  \
        --key-file $ETCD_KEY_FILE \
        --data-dir $ETCD_DATA_DIR/$ETCD_NODE1_NAME \
        --peer-cert-file $ETCD_PEER_CERT_FILE  \
        --peer-key-file $ETCD_PEER_KEY_FILE  \
        --peer-trusted-ca-file $CA_CERT_FILE \
        --peer-client-cert-auth  \
        --client-cert-auth \
        --log-output stdout &> $ETCD_LOG_DIR/$ETCD_NODE1_NAME.log &
    echo $! > $PID_DIR/etcd1

    $ETCD_BINARY \
        --name $ETCD_NODE2_NAME \
        --listen-peer-urls $ETCD_NODE2_LISTEN_URL \
        --initial-advertise-peer-urls $ETCD_NODE2_LISTEN_URL  \
        --advertise-client-urls $ETCD_NODE2_CLIENT_URL \
        --listen-client-urls $ETCD_NODE2_CLIENT_URL \
        --initial-cluster-state new \
        --initial-cluster $ETCD_NODE1_NAME=$ETCD_NODE1_LISTEN_URL,$ETCD_NODE2_NAME=$ETCD_NODE2_LISTEN_URL,$ETCD_NODE3_NAME=$ETCD_NODE3_LISTEN_URL \
        --trusted-ca-file $CA_CERT_FILE    \
        --cert-file $ETCD_CERT_FILE  \
        --key-file $ETCD_KEY_FILE \
        --data-dir $ETCD_DATA_DIR/$ETCD_NODE2_NAME \
        --peer-cert-file $ETCD_PEER_CERT_FILE  \
        --peer-key-file $ETCD_PEER_KEY_FILE  \
        --peer-trusted-ca-file $CA_CERT_FILE \
        --peer-client-cert-auth  \
        --client-cert-auth \
        --log-output stdout &> $ETCD_LOG_DIR/$ETCD_NODE2_NAME.log &
    echo $! > $PID_DIR/etcd2

    $ETCD_BINARY \
        --name $ETCD_NODE3_NAME \
        --listen-peer-urls $ETCD_NODE3_LISTEN_URL \
        --initial-advertise-peer-urls $ETCD_NODE3_LISTEN_URL \
        --advertise-client-urls $ETCD_NODE3_CLIENT_URL \
        --listen-client-urls $ETCD_NODE3_CLIENT_URL \
        --initial-cluster-state new \
        --initial-cluster $ETCD_NODE1_NAME=$ETCD_NODE1_LISTEN_URL,$ETCD_NODE2_NAME=$ETCD_NODE2_LISTEN_URL,$ETCD_NODE3_NAME=$ETCD_NODE3_LISTEN_URL \
        --trusted-ca-file $CA_CERT_FILE    \
        --cert-file $ETCD_CERT_FILE  \
        --key-file $ETCD_KEY_FILE \
        --data-dir $ETCD_DATA_DIR/$ETCD_NODE3_NAME \
        --peer-cert-file $ETCD_PEER_CERT_FILE  \
        --peer-key-file $ETCD_PEER_KEY_FILE  \
        --peer-trusted-ca-file $CA_CERT_FILE \
        --peer-client-cert-auth  \
        --client-cert-auth \
        --log-output stdout &> $ETCD_LOG_DIR/$ETCD_NODE3_NAME.log &
    echo $! > $PID_DIR/etcd3
}

function start_apiserver() {
    $K8S_KUBE_APISERVER_BINARY \
        --service-cluster-ip-range=$K8S_NETWORK \
        --etcd-certfile=$K8S_ADMIN_CERT_FILE  \
        --etcd-keyfile=$K8S_ADMIN_KEY_FILE \
        --etcd-cafile=$CA_CERT_FILE  \
        --etcd-servers=$ETCD_NODE1_CLIENT_URL,$ETCD_NODE2_CLIENT_URL,$ETCD_NODE3_CLIENT_URL  \
        --tls-cert-file=$K8S_APISERVER_CERT_FILE  \
        --tls-private-key-file=$K8S_APISERVER_KEY_FILE  \
        --client-ca-file=$CA_CERT_FILE  \
        --token-auth-file=$K8S_TOKEN_FILE  \
        --log-dir=$K8S_LOG_DIR  \
        --bind-address=0.0.0.0  \
        --enable-bootstrap-token-auth \
        --apiserver-count=2 \
        --secure-port=$K8S_KUBE_APISERVER_SECURE_PORT \
        --insecure-port=$K8S_KUBE_APISERVER_UNSECURE_PORT &
    echo $! > $PID_DIR/apiserver
}

function start_controller_manager() {
    $K8S_KUBE_CONTROLLER_MANAGER_BINARY  \
        --root-ca-file=$CA_CERT_FILE  \
        --cluster-signing-cert-file=$CA_CERT_FILE  \
        --cluster-signing-key-file=$CA_KEY_FILE  \
        --service-account-private-key-file=$CA_KEY_FILE  \
        --kubeconfig=$K8S_KUBE_CONFIG_FILE  \
	-v 0 \
        --port=$K8S_KUBE_CONTROLLER_MANAGER_PORT &
    echo $! > $PID_DIR/controllermanager
}

function start_scheduler() {
    $K8S_KUBE_SCHEDULER_BINARY  \
	-v 5 \
        --kubeconfig=$K8S_KUBE_CONFIG_FILE \
        --port=$K8S_KUBE_SCHEDULER_PORT &
    echo $! > $PID_DIR/scheduler
}

function start_kubelet() {
    sudo $K8S_KUBELET_BINARY --logtostderr=true \
	    --v=0 \
	    --kubeconfig=$K8S_KUBE_CONFIG_FILE \
	    --address=0.0.0.0 \
	    --allow-privileged=true \
	    --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0 \
	    --cgroups-per-qos=false \
	    --enforce-node-allocatable="" \
	    --cloud-provider=external \
	    --fail-swap-on=false &
    echo $! > $PID_DIR/kubelet

}

function clean() {
	rm -rf $CA_CERT_DIR $ETCD_CERT_DIR $ETCD_PEER_CERT_DIR $K8S_ADMIN_CERT_DIR $K8S_APISERVER_CERT_DIR
}

function create_certificate() {
	cd cert
	./init.sh
	cd ..
}

function init() {
    create_certificate

    TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
    echo "$TOKEN,$K8S_ADMIN_USER,10001,system:$K8S_ADMIN_USER" > $K8S_TOKEN_FILE
    $K8S_KUBECTL_BINARY config set-cluster $K8S_CLUSTER_NAME  \
                        --certificate-authority=$CA_CERT_FILE  \
                        --embed-certs=true  \
                        --server=https://$MASTER_IPV4:$K8S_KUBE_APISERVER_SECURE_PORT  \
                        --kubeconfig=$K8S_KUBE_CONFIG_FILE
    
    $K8S_KUBECTL_BINARY config set-credentials $K8S_ADMIN_USER  \
                        --client-certificate=$K8S_ADMIN_CERT_FILE \
                        --client-key=$K8S_ADMIN_KEY_FILE \
                        --embed-certs=true \
                        --token=$TOKEN  \
                        --kubeconfig=$K8S_KUBE_CONFIG_FILE

    $K8S_KUBECTL_BINARY config set-context $K8S_CONTEXT_NAME \
                        --cluster=$K8S_CLUSTER_NAME  \
                        --user=$K8S_ADMIN_USER \
                        --kubeconfig=$K8S_KUBE_CONFIG_FILE

    $K8S_KUBECTL_BINARY config use-context $K8S_CONTEXT_NAME \
                        --kubeconfig=$K8S_KUBE_CONFIG_FILE
}

function main() {
    init
    start_etcd
    start_apiserver
    start_controller_manager
    start_scheduler
}

main
