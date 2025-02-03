#!/usr/bin/env bash

# Monta o sistema de arquivos
yum install -y amazon-efs-utils
mkdir -p /mnt/efs
mount -t efs -o tls <efs_id>:/ /mnt/efs 
echo "<efs_id>:/ /mnt/efs efs _netdev,tls 0 0" >> /etc/fstab

# Atualiza pacotes e instala o Docker
yum update -y
sudo yum install -y libxcrypt-compat
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
usermod -a -G docker $USER

# Instala o docker compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Cria o arquivo docker compose
cat << EOF > /home/ec2-user/docker-compose.yml
version: '3'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: <endpoint_do_rds>.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: <segredo_do_rds>
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/efs/wp-content:/var/www/html/wp-content  
    restart: always
EOF

# Inicializa o contêiner do WordPress
sudo docker-compose -f /home/ec2-user/docker-compose.yml up -d