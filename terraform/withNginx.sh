#!/bin/bash
sudo apt update -y 
sudo adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
sudo apt install docker-compose -y 
sudo apt install nginx -y
sudo ufw allow "Nginx Full"
cat << EOF > /etc/nginx/sites-available/gitea
server {
  
    server_name localhost;

    root /var/www/html;

    location / {
    
        proxy_pass http://localhost:3000;
        proxy_set_header HOST \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/gitea /etc/nginx/sites-enabled/gitea
sudo systemctl restart nginx
mkdir gitea
cd gitea
xuid=$(id -u git)
xgid=$(id -g git)
cat << EOF > /home/ubuntu/docker-compose.yaml
version: "3"
networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.17.3
    container_name: gitea
    environment:
      - USER_UID=$xuid
      - USER_GID=$xgid
      - GITEA__database__DB_TYPE=mysql
      - GITEA__database__HOST=db:3306
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD=gitea
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
    depends_on:
      - db

  db:
    image: mysql:8
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=gitea
      - MYSQL_USER=gitea
      - MYSQL_PASSWORD=gitea
      - MYSQL_DATABASE=gitea
    networks:
      - gitea
    volumes:
      - ./mysql:/var/lib/mysql
EOF
cd /home/ubuntu
sudo docker-compose up -d