#!/bin/bash

set -e

echo "=== Labsyncer VPS Setup Script ==="

echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo "Installing Java..."
sudo apt install -y openjdk-17-jdk

echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "Installing Nginx..."
sudo apt install -y nginx

echo "Installing PM2..."
sudo npm install -g pm2

echo "Installing Maven..."
sudo apt install -y maven

 Clone repository (uncomment and modify if using Git)
 echo "Cloning repository..."
 git clone https://github.com/abhinandanjoshii/Labsyncer.git
 cd Labsyncer

echo "Building Java backend..."
mvn clean package

echo "Building frontend..."
cd ui
npm install
npm run build
cd ..

echo "Setting up Nginx..."

if [ -e /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
    echo "Removed default Nginx site configuration."
fi

echo "Creating /etc/nginx/sites-available/labsyncer..."
cat <<EOF | sudo tee /etc/nginx/sites-available/labsyncer
server {
    listen 80;
    server_name _;

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

sudo ln -sf /etc/nginx/sites-available/labsyncer /etc/nginx/sites-enabled/labsyncer

sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
    echo "Nginx configured and restarted successfully."
else
    echo "Nginx configuration test failed. Please check /etc/nginx/nginx.conf and /etc/nginx/sites-available/peerlink."
    exit 1
fi

# we can add ssh
echo "Starting backend with PM2..."
CLASSPATH="target/p2p-1.0-SNAPSHOT.jar:$(mvn dependency:build-classpath -DincludeScope=runtime -Dmdep.outputFile=/dev/stdout -q)"
pm2 start --name peerlink-backend java -- -cp "$CLASSPATH" p2p.App

echo "Starting frontend with PM2..."
cd ui
pm2 start npm --name peerlink-frontend -- start
cd ..

pm2 save

echo "Setting up PM2 to start on boot..."
pm2 startup

echo "=== Setup Complete ==="
echo "Labsyncer is now running on your VPS!"
echo "Backend API: http://localhost:8080 (Internal - accessed via Nginx)"
echo "Frontend: http://your_lightsail_public_ip (Access via your instance's IP address)"
echo "You can access your application using your Lightsail instance's public IP address in your browser."
