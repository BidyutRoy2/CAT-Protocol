#!/bin/bash

echo "-----------------------------------------------------------------------------"
curl -s https://raw.githubusercontent.com/BidyutRoy2/BidyutRoy2/main/logo.sh | bash
echo "-----------------------------------------------------------------------------"

# Colors for styling
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_CYAN="\e[36m"
COLOR_RESET="\e[0m"

# Function to display and open links
display_and_open_links() {
    local telegram_link="https://t.me/hiddengemnews"

    echo -e "\nWelcome to the Fractal Node Setup Script.\n"
    echo -e "Join Telegram channel: ${COLOR_BLUE}${telegram_link}${COLOR_RESET}"
}

# Call the function to display and potentially open links
display_and_open_links

# Rest of the script remains the same...

# Log function with emoji support
log() {
    echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}

# Error handling with emoji support
handle_error() {
    echo -e "${COLOR_RED}❌ Error: $1${COLOR_RESET}"
    exit 1
}

Crontab_file="/usr/bin/crontab"

# Check if root user
check_root() {
    [[ $EUID != 0 ]] && echo "Error: Not currently root user. Please switch to root account or use 'sudo su' to obtain temporary root privileges." && exit 1
}

# Install dependencies and full node
install_env_and_full_node() {
    check_root
    # Update and upgrade system
    sudo apt update && sudo apt upgrade -y

    # Install necessary tools and libraries
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu unzip zip docker.io -y

    # Get the latest version of Docker Compose
    VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
    DESTINATION=/usr/local/bin/docker-compose
    sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
    sudo chmod 755 $DESTINATION

    # Install Node.js and Yarn
    sudo apt-get install npm -y
    sudo npm install n -g
    sudo n stable
    sudo npm i -g yarn

    # Clone CAT Token Box project and install and build
    git clone https://github.com/CATProtocol/cat-token-box
    cd cat-token-box
    sudo yarn install
    sudo yarn build

    # Set up Docker environment and start services
    cd ./packages/tracker/
    sudo chmod 777 docker/data
    sudo chmod 777 docker/pgdata
    sudo docker-compose up -d

    # Build and run Docker image
    cd ../../
    sudo docker build -t tracker:latest .
    sudo docker run -d \
        --name tracker \
        --add-host="host.docker.internal:host-gateway" \
        -e DATABASE_HOST="host.docker.internal" \
        -e RPC_HOST="host.docker.internal" \
        -p 3000:3000 \
        tracker:latest

    # Create configuration file
    echo '{
      "network": "fractal-mainnet",
      "tracker": "http://127.0.0.1:3000",
      "dataDir": ".",
      "maxFeeRate": 30,
      "rpc": {
          "url": "http://127.0.0.1:8332",
          "username": "bitcoin",
          "password": "opcatAwesome"
      }
    }' > ~/cat-token-box/packages/cli/config.json

    # Create mint script
    echo '#!/bin/bash

    command="sudo yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5"

    while true; do
        $command

        if [ $? -ne 0 ]; then
            echo "Command execution failed, exiting loop"
            exit 1
        fi

        sleep 1
    done' > ~/cat-token-box/packages/cli/mint_script.sh
    chmod +x ~/cat-token-box/packages/cli/mint_script.sh
}

# Create wallet
create_wallet() {
  echo -e "\n"
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet create
  echo -e "\n"
  sudo yarn cli wallet address
  echo -e "Please save the wallet address and mnemonic phrase created above."
}

# Start mint script
start_mint_cat() {
  cd ~/cat-token-box/packages/cli
  bash ~/cat-token-box/packages/cli/mint_script.sh
}

# Check node synchronization log
check_node_log() {
  docker logs -f --tail 100 tracker
}

# Check wallet balance
check_wallet_balance() {
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet balances
}

# Display main menu
echo -e "\n
Welcome to the CAT Token Box installation script.
This script is completely free and open source.
Please choose an operation as needed:
1. Install dependencies and full node
2. Create wallet
3. Start minting CAT
4. Check node synchronization log
5. Check wallet balance
"

# Get user selection and perform corresponding operation
read -e -p "Please enter your choice: " num
case "$num" in
1)
    install_env_and_full_node
    ;;
2)
    create_wallet
    ;;
3)
    start_mint_cat
    ;;
4)
    check_node_log
    ;;
5)
    check_wallet_balance
    ;;
*)
    echo -e "Error: Please enter a valid number."
    ;;
esac
