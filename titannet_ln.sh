#!/bin/bash

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    sudo apt remove -y docker docker-engine docker.io containerd runc
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common lsb-release gnupg2
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Add current user to Docker group
if ! groups $USER | grep -q '\bdocker\b'; then
    sudo groupadd docker
    sudo usermod -aG docker $USER
    echo "You have been added to the 'docker' group. Please re-login to apply group changes."
    exit 1
fi

# Update network buffer settings
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400
if ! sudo sysctl -p; then
    echo "Failed to apply sysctl settings. Ensure you have sufficient privileges."
    exit 1
fi

# Pull Titan Docker image
docker pull nezha123/titan-edge

# Stop and remove any existing Titan container if present
if docker ps -a --format '{{.Names}}' | grep -q '^titan$'; then
    docker stop titan
    docker rm titan
fi

# Wait for Docker and sysctl changes to take effect
sleep 10

# Create Titan configuration directory
mkdir -p ~/.titanedge

# Launch Titan
docker run --name titan --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge

# Wait for the container to initialize
sleep 30

# Bind identity code
identity_code=$(cat identity_code.txt)
docker run --rm -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash="$identity_code" https://api-test1.container1.titannet.io/api/v2/device/binding

# Restart Titan (optional)
if docker ps -a --format '{{.Names}}' | grep -q '^titan$'; then
    docker stop titan
    docker rm titan
fi

docker run --name titan --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge
