#!/bin/bash

# Nodewatch Backend Interactive Setup Script
echo "======================================"
echo "    Nodewatch Backend Deployment      "
echo "======================================"
echo ""
echo "Hi! 👋 This script will set up the necessary middleware (a Docker container"
echo "and its supporting configuration) so Nodewatch can communicate with the app and"
echo "notify users of state changes. It uses n8n within a Docker container to handle"
echo "the workflow. If you're using Docker Compose and want to add it to your YAML"
echo "file, make sure to run this script in the same directory as that file."
echo ""
echo "Note: this script can install Docker for you if it doesn't detect it on your system."
echo ""
echo "🐳 Checking to see if Docker is installed..."
echo ""
sleep 3

# 1. Check for Docker & Install Minimum Packages if Missing
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed on this system."
    read -p "Would you like this script to install Docker automatically? (y/N): " INSTALL_DOCKER
    echo ""
    
    if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
        echo "Installing the required packages..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        echo "✅ Docker installed successfully."
        echo ""
    else
        echo "❌ Docker is required to run the Nodewatch backend. Aborting setup."
        exit 1
    fi
fi

# 2. Determine Deployment Preference
echo "How would you like to deploy the Nodewatch backend?"
echo "1) Standalone container (using 'docker run')"
echo "2) Add to a docker-compose.yml file (using 'docker compose')"
read -p "Select an option [1 or 2]: " DEPLOY_MODE
echo ""

# 3. Gather User Configuration
echo "Next, we need the Nagios base URL that users typically use to access Nagios"
echo "on the web. This assumes VPNs aren't required to access the page."
read -p "URL: " NAGIOS_URL
NAGIOS_URL=${NAGIOS_URL%/} # Strip trailing slash if accidentally added

read -p "Next, the port for n8n to run on [Default: 5678]: " N8N_PORT
N8N_PORT=${N8N_PORT:-5678}

echo ""
echo "⚙️  Preparing workflow for $NAGIOS_URL..."
sed "s|%%NAGIOS_URL%%|$NAGIOS_URL|g" nodewatch-workflow.json > imported-workflow.json

# 4. Execute Deployment
if [ "$DEPLOY_MODE" == "2" ]; then
    # -- DOCKER COMPOSE ROUTE --
    
    # Check for docker compose availability
    if docker compose version &>/dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif docker-compose --version &>/dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        echo "❌ Docker Compose not found on this system. Aborting."
        rm imported-workflow.json
        exit 1
    fi
    
    COMPOSE_FILE="docker-compose.yml"
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "📄 No existing $COMPOSE_FILE found. Creating a fresh one..."
        cat > "$COMPOSE_FILE" <<EOF
services:
  nodewatch-backend:
    image: n8nio/n8n
    container_name: nodewatch-backend
    restart: unless-stopped
    ports:
      - "$N8N_PORT:5678"
    volumes:
      - nodewatch_n8n_data:/home/node/.n8n

volumes:
  nodewatch_n8n_data:
EOF
    else
        echo "🔍 Found existing $COMPOSE_FILE. Backing up to ${COMPOSE_FILE}.bak..."
        cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"
        
        echo "💉 Injecting Nodewatch service into existing configuration..."
        awk -v port="$N8N_PORT" '
        /^services:/ { print; next }
        /^volumes:/ {
            if (!s_done) {
                print "  nodewatch-backend:"
                print "    image: n8nio/n8n"
                print "    container_name: nodewatch-backend"
                print "    restart: unless-stopped"
                print "    ports:"
                print "      - \"" port ":5678\""
                print "    volumes:"
                print "      - nodewatch_n8n_data:/home/node/.n8n"
                s_done=1
            }
            print
            print "  nodewatch_n8n_data:"
            v_done=1
            v_exists=1
            next
        }
        /^networks:/ {
            if (!s_done) {
                print "  nodewatch-backend:"
                print "    image: n8nio/n8n"
                print "    container_name: nodewatch-backend"
                print "    restart: unless-stopped"
                print "    ports:"
                print "      - \"" port ":5678\""
                print "    volumes:"
                print "      - nodewatch_n8n_data:/home/node/.n8n"
                s_done=1
            }
            print
            next
        }
        { print }
        END {
            if (!s_done) {
                print "  nodewatch-backend:"
                print "    image: n8nio/n8n"
                print "    container_name: nodewatch-backend"
                print "    restart: unless-stopped"
                print "    ports:"
                print "      - \"" port ":5678\""
                print "    volumes:"
                print "      - nodewatch_n8n_data:/home/node/.n8n"
            }
            if (!v_exists) {
                print "volumes:"
                print "  nodewatch_n8n_data:"
            }
        }' "$COMPOSE_FILE" > tmp.yml && mv tmp.yml "$COMPOSE_FILE"
    fi
    
    echo "🐳 Starting specific container via Compose..."
    $DOCKER_COMPOSE_CMD up -d nodewatch-backend > /dev/null

else
    # -- DOCKER RUN ROUTE --
    echo "📦 Creating Docker volume (nodewatch_n8n_data)..."
    docker volume create nodewatch_n8n_data > /dev/null

    echo "🐳 Starting standalone n8n container on port $N8N_PORT..."
    docker run -d \
      --name nodewatch-backend \
      --restart unless-stopped \
      -p $N8N_PORT:5678 \
      -v nodewatch_n8n_data:/home/node/.n8n \
      n8nio/n8n > /dev/null
fi

echo "⏳ Waiting 15 seconds for n8n to fully initialise..."
sleep 15

# 5. Import the tailored workflow
echo "📥 Importing configuration into n8n..."
docker cp imported-workflow.json nodewatch-backend:/tmp/workflow.json
docker exec nodewatch-backend n8n import:workflow --input=/tmp/workflow.json > /dev/null

# 6. Clean up temporary files
docker exec nodewatch-backend rm /tmp/workflow.json
rm imported-workflow.json

echo ""
echo "======================================"
echo "✅ Setup complete!"
echo "======================================"
echo "1. In your browser, access this machine's IP or domain using port $N8N_PORT."
echo "2. Set up your n8n owner account."
echo "3. Open the 'Nodewatch Backend Pipeline' workflow."
echo "4. The workflow has been pre-configured for $NAGIOS_URL."
echo "   Double-click the 'Get Services' and 'Get Hosts' nodes to add your Nagios HTTP Basic Auth credentials."
echo "   It's recommended to save the credentials as a configuration so you can easily apply it to both."
echo "5. Click 'Publish' in the top right corner of the canvas to make the workflow active."
echo ""
echo "⚠️  FIREWALL & NETWORK ROUTING:"
echo "   Ensure port $N8N_PORT is open on this machine's firewall (e.g., UFW, firewalld)."
echo "   If accessing the app from outside this local network, ensure the port is forwarded"
echo "   on your router or permitted by your cloud provider's security groups."
echo ""
echo "📱 In the Nodewatch iOS App, you can now connect using:"
echo "   Webhook URL: http://<this-server-ip-or-domain>"
echo "   Port:        $N8N_PORT"
echo ""
