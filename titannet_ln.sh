if ! command -v docker &> /dev/null; then
    sudo apt remove -y docker docker-engine docker.io containerd runc
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common lsb-release gnupg2
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
fi

if ! command -v docker-compose &> /dev/null; then
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

if ! groups $USER | grep -q '\bdocker\b'; then
    sudo groupadd docker
    sudo usermod -aG docker $USER
fi

docker pull nezha123/titan-edge

# Stop and remove any existing Titan container if present
if docker ps -a --format '{{.Names}}' | grep -q '^titan$'; then
    docker stop titan
    docker rm titan
fi

sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400
sudo sysctl -p


mkdir -p ~/.titanedge

# Launch Titan
docker run --name titan --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge

# Bind identity code
identity_code=$(cat identity_code.txt)
docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash="$identity_code" https://api-test1.container1.titannet.io/api/v2/device/binding
