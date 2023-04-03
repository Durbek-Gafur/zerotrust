# Zerotrust

We have 6 EC2 instances, 1 for controller, 1 for ground station and 4 drones (2 of them observer and  sensing drones).

Set up ec2 instances, t2.micro would be fine.

Run on controller node:

export K3S_NODE_NAME=controller && export INSTALL_K3S_EXEC="--write-kubeconfig ~/.kube/config --write-kubeconfig-mode 666 --node-external-ip {controller_node_ip} --tls-san {controller_node_ip}" && curl -sfL https://get.k3s.io | sh -s -

After installing k3s, run on contoller node the following command :
sudo cat /var/lib/rancher/k3s/server/node-token

Then on drones and ground station nodes, change the name of K3S_NODE_NAME :

export K3S_NODE_NAME=drone1 && export K3S_URL="https://{node1_addr}:6443" && export K3S_TOKEN={K3S_TOKEN} && curl -sfL "https://get.k3s.io" | sh -s -


Finally on controller node, run  to make sure all nodes have joined the cluster:
sudo cat /var/lib/rancher/k3s/server/node-token
