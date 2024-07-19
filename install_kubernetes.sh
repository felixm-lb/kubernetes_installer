CURRENT_DIR=`pwd`
INSTALL_KUBERENETS_VERSION="v1.1"

# Display help menu
DisplayHelp()
{
    echo "This script will configure the installation and install Lightbits on VMs in the cloud or generic server. Script version: $INSTALL_KUBERNETES_VERSION
   
    Syntax: ${0##*/} [-o|m|w|u|p]
    options:                                     example:
    o    Target Operating System.                el, deb
    m    Master Node(s) IPs.                     \"10.0.0.1,10.0.0.2,10.0.0.3\"
    w    Worker Node(s) IPs.                     \"10.0.0.1,10.0.0.2,10.0.0.3\"
    u    Username.                               root
    p    Password - use SINGLE quotes ''.        'p@ssword12345!!'
    s    Silent.                                 used to ignore logo output

    Full Example - EL
    ${0##*/} -o el -m \"10.0.0.1\" -w \"10.0.0.2,10.0.0.3,10.0.0.4\" -u root -p 'p@ssword12345!!'

    Full Example - Ubuntu
    ${0##*/} -o deb -m \"10.0.0.1\" -w \"10.0.0.2,10.0.0.3,10.0.0.4\" -u root -p 'p@ssword12345!!'

    After
    sudo kubeadm init --control-plane-endpoint=<your_master_node_hostname>

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
"
}

# Get entered options and set them as variables
SetOptions()
{
    # Get and set the options
    local OPTIND
    while getopts ":h:o:m:w:u:p:s" option; do # f has no colon so it doesn't accept parameters
        case "${option}" in
            h)
                DisplayHelp
                exit;;
            o)
                operating_system="$OPTARG"
                ;;
            m)
                master_node_ips="$OPTARG"
                ;;
            w)
                worker_node_ips="$OPTARG"
                ;;
            u)
                username="$OPTARG"
                ;;
            p)
                password="$OPTARG"
                ;;
            s)
                silent=true
                ;;
            :)
                if [ "${OPTARG}" != "h" ]; then
                    printf "missing argument for -%s\n" "$OPTARG" >&2
                fi
                DisplayHelp
                exit 1
                ;;
            \?)
                printf "illegal option: -%s\n" "$OPTARG" >&2
                DisplayHelp
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

# Check parameters
RunCheckParameters()
{
    # Check that the OS has been provided
    CheckOperatingSystem()
    {
        if [ -z "${operating_system}" ]; then
            echo "No operating system provided!"
            DisplayHelp
            exit 1
        fi
    }

    # Parse master node ips into array and run checks
    ParseMasterNodeIPs()
    {
        if [ -z "${master_node_ips}" ]; then
            echo "No master node IPs found!"
            DisplayHelp
            exit 1
        fi

        # Convert string into array
        master_node_ips_array=($(echo "${master_node_ips}" | tr ',' '\n'))
        # Check no duplicate IPs provided
        uniqueNum=$(printf '%s\n' "${master_node_ips_array[@]}"|awk '!($0 in seen){seen[$0];c++} END {print c}')
        if [[ "${uniqueNum}" != "${#master_node_ips_array[@]}" ]]; then
            echo "Duplicate values found in data addresses: ${master_node_ips}, please remove them!"
            exit 1
        fi
    }

    # Parse master node ips into array and run checks
    ParseWorkerNodeIPs()
    {
        if [ -z "${worker_node_ips}" ]; then
            echo "No master node IPs found!"
            DisplayHelp
            exit 1
        fi

        # Convert string into array
        worker_node_ips_array=($(echo "${worker_node_ips}" | tr ',' '\n'))
        # Check no duplicate IPs provided
        uniqueNum=$(printf '%s\n' "${worker_node_ips_array[@]}"|awk '!($0 in seen){seen[$0];c++} END {print c}')
        if [[ "${uniqueNum}" != "${#worker_node_ips_array[@]}" ]]; then
            echo "Duplicate values found in data addresses: ${worker_node_ips}, please remove them!"
            exit 1
        fi
    }

    # Check that the username for ssh login has been provided
    CheckUsername()
    {
        if [ -z "${username}" ]; then
            echo "No username provided!"
            DisplayHelp
            exit 1
        fi
    }

    # Check that the password has been provided
    CheckPassword()
    {
        if [ -z "${password}" ]; then
            echo "No password provided!"
            DisplayHelp
            exit 1
        fi
    }

    CheckOperatingSystem
    ParseMasterNodeIPs
    ParseWorkerNodeIPs
    CheckUsername
    CheckPassword
}

# Display the program logo
EchoLogo()
{
    if [[ -z "${silent}" ]]; then
    cat <<'END_LOGO'
         _     _       _     _   _     _ _       
        | |   (_) __ _| |__ | |_| |__ (_) |_ ___ 
        | |   | |/ _` | '_ \| __| '_ \| | __/ __|
        | |___| | (_| | | | | |_| |_) | | |_\__ \
        |_____|_|\__, |_| |_|\__|_.__/|_|\__|___/
         ___     |___/ _        _ _              
        |_ _|_ __  ___| |_ __ _| | | ___ _ __    
         | ||  _ \/ __| __/ _` | | |/ _ \  __|   
         | || | | \__ \ || (_| | | |  __/ |      
        |___|_| |_|___/\__\__,_|_|_|\___|_|        

                             ==+**                  
                ######*==  ====+*****              
            #########+===  =====+*******           
          ##########====== ======*********         
        ###########+====== ======####*******       
      #############===---- ======*######*****      
     #*###********+------- ------*########****     
     ============--------- ------*########*****    
       ========--------:::  -----##########*****   
   ===     ===-------:::::: :::::--------=====+**  
 #*=======      ----:::::      ::::-------=======  
 ***==========      :::          :::-------=====   
 *****=========----               :::------=       
 ********+====-----:::                             
 ******#######+==-::::            ::::----=======++
 ******################          ::::----======*##*
 ******###############+..       ::::----==+*###### 
  ******##############-::..:::  ::---############# 
  ******##############::::::::  -----*############ 
   ******############*-::::::   ---==+###########  
    *******##########+-------   =====+##########   
     *******#########+-------   =====+#########    
       ********######*=======   =====*#######      
        ************#*=======   =====#######       
           ***********======    =====####          
             *********+=====    ====###            
                *******+===                        
                      **=                          
END_LOGO
    fi
}

# Check installer OS and major version
CheckInstallerOS()
{
    local ALLOWED_OS="rhel centos alma almalinux rocky ubuntu"
    echo "Checking installer OS"
    OS_TYPE=`cat /etc/os-release | grep -o -P '(?<=^ID=).*' | tr -d '"'`
    OS_VERSION=`cat /etc/os-release | grep -o -P '(?<=VERSION_ID=).*(?=\.)' | tr -d '"'`

    if [[ "${ALLOWED_OS}" =~ (^|[[:space:]])"${OS_TYPE}"($|[[:space:]]) ]]; then
        echo "OS is ${OS_TYPE} version ${OS_VERSION}"
    else
        echo "OS not supported for install, please use ${ALLOWED_OS}"
        exit 1
    fi
}

# Run/Install program pre-checks
RunSoftwarePrecheck()
{
    # Installs prerequisite software on the installer
    InstallInstallerSoftware()
    {
        # Install packages with apt
        InstallForUbuntu()
        {
            echo "Installing using apt"
            sudo apt-get -qq update
            sudo apt-get -qq install pssh sshpass wget
        }

        # Install packages with yum
        InstallForEL()
        {
            echo "Installing using yum"
            sudo yum install -qy "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm"
            sudo yum install -qy yum-utils pssh sshpass wget
        }

        echo "Installing tools"
        echo "Installing for ${OS_TYPE} v.${OS_VERSION}"
        if [[ "${OS_TYPE}" == "ubuntu" ]]; then
            InstallForUbuntu
        else
            InstallForEL
        fi
    }

    InstallInstallerSoftware
}

# Create clients files for pssh to use
CreatePSSHClientFiles()
{
    CreateCommonClientFile()
    {
        echo "Creating common pssh clients file"
        echo "" > "${CURRENT_DIR}/all_clients"
        for master_ip in ${master_node_ips_array[@]}; do
            echo "${username}@${master_ip}" >> "${CURRENT_DIR}/all_clients"
        done
        for worker_ip in ${worker_node_ips_array[@]}; do
            echo "${username}@${worker_ip}" >> "${CURRENT_DIR}/all_clients"
        done
    }

    CreateMasterClientFile()
    {
        echo "Creating master pssh clients file"
        echo "" > "${CURRENT_DIR}/master_clients"
        for master_ip in ${master_node_ips_array[@]}; do
            echo "${username}@${master_ip}" >> "${CURRENT_DIR}/master_clients"
        done
    }

    CreateWorkerClientFile()
    {
        echo "Creating worker pssh clients file"
        echo "" > "${CURRENT_DIR}/worker_clients"
        for worker_ip in ${worker_node_ips_array[@]}; do
            echo "${username}@${worker_ip}" >> "${CURRENT_DIR}/worker_clients"
        done
    }

    CreateCommonClientFile
    CreateMasterClientFile
    CreateWorkerClientFile
}

# Run the install on nodes
RunInstall()
{
    # Workaround for pssh being called different things
    if ! [ -x "$(command -v pssh)" ]; then
        PSSH_COMMAND="parallel-ssh"
    else
        PSSH_COMMAND="pssh"
    fi

    # Run the install that's common for worker and master for EL
    RunInstallELCommon()
    {
        echo "Install for All Nodes"
        read -r -d '' ELCommonCommands << EOF
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sudo dnf install -y iproute-tc
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y --nogpgcheck docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
cat > /etc/yum.repos.d/kubernetes.repo << EOL
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOL
sudo dnf install -y kubeadm kubelet kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet
sudo systemctl start kubelet
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml  
service containerd restart
service kubelet restart
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
EOF

        sshpass -p ${password} ${PSSH_COMMAND} -h "${CURRENT_DIR}/${clusterName}/all_clients" -x '-o StrictHostKeyChecking=false' -l root -A -t 900 -i "${ELCommonCommands}"
    }

    # Run the install that's for master for EL
    RunInstallELMaster()
    {
        # Nothing here yet
        echo "Install for Master Nodes"
    }

    # Run the install that's common for worker and master for EL
    RunInstallUbuntuCommon()
    {
        echo "Install for All Nodes"
        read -r -d '' UbuntuCommonCommands << EOF
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo tee /etc/modules-load.d/containerd.conf << EOL
overlay
br_netfilter
EOL
sudo modprobe br_netfilter
sudo modprobe overlay
sudo modprobe nvme_tcp
sudo tee /etc/sysctl.d/kubernetes.conf << EOL
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOL
sudo sysctl --system
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
EOF

        sshpass -p ${password} ${PSSH_COMMAND} -h "${CURRENT_DIR}/${clusterName}/all_clients" -x '-o StrictHostKeyChecking=false' -l root -A -t 900 -i "${UbuntuCommonCommands}"
    }

    if [ "${operating_system}" == "el" ]; then
        RunInstallELCommon
    else
        RunInstallUbuntuCommon
    fi
}

# Run the program in order
Run()
{
    SetOptions "$@"
    EchoLogo
    RunCheckParameters
    CheckInstallerOS
    RunSoftwarePrecheck
    CreatePSSHClientFiles
    RunInstall
}

Run "$@"
