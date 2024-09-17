#!/usr/bin/env bash

# make sure that curl is installed
if [ $(command -v curl) ]; then 
    echo "curl is existed"; 
else 
    sudo apt update >/dev/null 2>&1
    sudo apt install curl -y >/dev/null 2>&1
    echo "curl is installed"
fi

# make sure that nvm is installed
if [ -d "${HOME}/.nvm/.git" ]; then 
    echo "nvm is existed"; 
    source "${HOME}/.nvm/nvm.sh" >/dev/null 2>&1
else 
    curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash >/dev/null 2>&1
    source "${HOME}/.nvm/nvm.sh" >/dev/null 2>&1
    echo "nvm is installed"
fi

# make sure that node is installed
if [ $(command -v node) ]; then 
    echo "node is existed"
else 
    nvm install --lts >/dev/null 2>&1
    echo "node is installed"
fi

# make sure that nginx is installed
if [ $(command -v nginx) ]; then
    echo "nginx is existed"
else
    sudo apt update >/dev/null 2>&1
    sudo apt install nginx -y >/dev/null 2>&1
    echo "nginx is installed"
fi

# make sure that nginx is started
sudo systemctl status nginx >/dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo systemctl enable nginx --now >/dev/null 2>&1
    echo "nginx started"
else
    echo "nginx is already started"
fi

# make sure that firewall is configured and enabled
sudo ufw allow 'Nginx FULL'
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
#sudo ufw enable

SOURCE_USER='sshuser'
DESTINATION_USER='marat'
SOURCE_IP='10.0.2.15'
DESTINATION_IP='10.0.2.4'
SOURCE_SERVER_FOLDER='/var/app/devops-js-app/api'
DESTINATION_SERVER_FOLDER='devops-js-app.net/api'
SOURCE_CLIENT_FOLDER='/var/www/sites/devops-js-app.net'
DESTINATION_CLIENT_FOLDER='devops-js-app.net'
NGINX_FOLDER='/etc/nginx'

echo -e "\nCreating destination server folder..."
sudo mkdir -p "/var/app/${DESTINATION_SERVER_FOLDER}"

echo -e "\nChange ownership of the destination server folder..."
sudo chown -R "${DESTINATION_USER}:${DESTINATION_USER}" "/var/app/${DESTINATION_SERVER_FOLDER}"

echo -e "\nCopying server files..."
scp -Cri /home/marat/id_ecdsa "${SOURCE_USER}@${SOURCE_IP}:${SOURCE_SERVER_FOLDER}/{dist,package.json}" "/var/app/${DESTINATION_SERVER_FOLDER}/"

echo -e "\nInstalling server dependencies..."
cd "/var/app/${DESTINATION_SERVER_FOLDER}"
npm install --verbose

echo -e "\nStarting server (REST API)..."
npm run start:pm2

echo -e "\nCreating destination client folder..."
sudo mkdir -p "/var/www/sites/${DESTINATION_CLIENT_FOLDER}"

echo -e "\nChange ownership of the destination client folder..."
sudo chown -R ${DESTINATION_USER}:${DESTINATION_USER} "/var/www/sites/${DESTINATION_CLIENT_FOLDER}"

echo -e "\nCopying client files..."
scp -Cri /home/marat/id_ecdsa "${SOURCE_USER}@${SOURCE_IP}:${SOURCE_CLIENT_FOLDER}/*" "/var/www/sites/${DESTINATION_CLIENT_FOLDER}/"
sudo chown -R www-data:www-data "/var/www/sites/${DESTINATION_CLIENT_FOLDER}"

if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Deleting default nginx site config..."
    sudo unlink /etc/nginx/sites-enabled/default
fi

echo -e "\nCopying nginx site config..."
scp -Cri /home/marat/id_ecdsa "${SOURCE_USER}@${SOURCE_IP}:${NGINX_FOLDER}/sites-enabled/devops-js-app.net.conf" "./devops-js-app.net.conf"
sudo cp ./devops-js-app.net.conf "${NGINX_FOLDER}/sites-enabled/devops-js-app.net.conf"
sudo chown -R www-data:www-data "${NGINX_FOLDER}/sites-enabled/devops-js-app.net.conf"
rm -f ./devops-js-app.net.conf

echo -e "\nCopying site certs..."
cd "${HOME}"
mkdir -p ./certs
scp -Cri /home/marat/id_ecdsa "${SOURCE_USER}@${SOURCE_IP}:/home/sshuser/devops-js-app.net.crt" "./certs/"
scp -Cri /home/marat/id_ecdsa "${SOURCE_USER}@${SOURCE_IP}:/home/sshuser/devops-js-app.net.key" "./certs/"
sudo cp "./certs/devops-js-app.net.crt" "${NGINX_FOLDER}/"
sudo cp "./certs/devops-js-app.net.key" "${NGINX_FOLDER}/"
sudo chown -R www-data:www-data "${NGINX_FOLDER}/devops-js-app.net.crt"
sudo chown -R www-data:www-data "${NGINX_FOLDER}/devops-js-app.net.key"
rm -rf ./certs

if ! grep -qF 'devops-js-app.net' /etc/hosts; then
    echo -e "\nAdding hostname alias..."
    echo -e "127.0.0.1\tdevops-js-app.net" | sudo tee -a /etc/hosts
fi

echo -e "\nTesting nginx config..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo -e "\nRestarting nginx..."
    sudo systemctl restart nginx
fi

