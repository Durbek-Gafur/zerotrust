# ZeroTrust

This repository contains instructions for setting up a ZeroTrust environment using K3s. ZeroTrust is an approach to security that assumes all devices, networks, and users are untrusted, and access is granted only after proper authentication and verification.

## Getting Started

### Prerequisites

You will need to have access to six EC2 instances: one for the controller, one for the ground station, and four drones (two observer drones and two sensing drones). A t2.micro instance is sufficient for this setup.

### Setting up the Cluster

To set up the cluster, follow these steps:

1. On the controller node, run the following command, replacing `{controller_node_ip}` with the IP address of the controller node:

```bash
#!/bin/bash
export K3S_NODE_NAME=controller && export INSTALL_K3S_EXEC="--write-kubeconfig ~/.kube/config --write-kubeconfig-mode 666 --node-external-ip {controller_node_ip} --tls-san {controller_node_ip}" && curl -sfL https://get.k3s.io | sh -s -
```

This command installs K3s on the controller node and sets it up as the primary node in the cluster.

2. After installing K3s, run the following command on the controller node:

sudo cat /var/lib/rancher/k3s/server/node-token


This command generates a unique token for the cluster. You will need this token to join the other nodes to the cluster.

3. On the drones and ground station nodes, run the following command for each node, replacing `{node1_addr}` with the IP address of the node and `{K3S_TOKEN}` with the token generated in step 2:

export K3S_NODE_NAME=drone1 && export K3S_URL="https://{node1_addr}:6443" && export K3S_TOKEN={K3S_TOKEN} && curl -sfL "https://get.k3s.io" | sh -s -


This command installs K3s on the drone or ground station node and joins it to the cluster.

4. Finally, on the controller node, run the following command to ensure that all nodes have joined the cluster:

sudo kubectl get nodes


This command lists all the nodes in the cluster. Make sure that all the nodes you set up are listed here.

### Creating Pods and Policies

Once the cluster is set up, you can create pods and policies to define the behavior of the ZeroTrust environment. Pods are groups of one or more containers that run together on a node, while policies define the rules and permissions for accessing the pods.

To create pods and policies, follow these steps:

1. After downloading the current GitHub repo, navigate to the `yaml` directory:

cd zerotrust/yaml


2. Apply the `pods.yaml` file to create the necessary pods:

kubectl apply -f pods.yaml


3. Apply the `policy-extended.yaml` file to create the necessary policies:

kubectl apply -f policy-extended.yaml

