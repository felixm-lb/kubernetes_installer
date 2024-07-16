Installer for kubernetes
=

Information
--
Bash script to install kuberenetes on a set of Linux machines including controllers and worker nodes

Instructions
--
1. Bring up your clients in Debian or EL
2. Run the script passing your OS type (el or deb)
3. Run `kubeadm init --control-plane-endpoint=<your_controller_node_hostname>`1
4. Run `kubeadm join <your_master_node_hostname>:6443 --token <your_master_node_token> --discovery-token-ca-cert-hash <your_master_node_discovery_hash>` on worker nodes
5. Install networking of your choice, e.g. using Calico:  `kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml`

Version History
--
07/15/2024, v1.0: Verified basic common installation for Ubuntu and EL 9
