#!/bin/bash

#Variables
repo="bootcamp-devops-2023"
USERID=$(id -u)
#colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
LYELLOW='\033[1;33m'
DISCORD="https://discord.com/api/webhooks/1154865920741752872/au1jkQ7v9LgQJ131qFnFqP-WWehD40poZJXRGEYUDErXHLQJ_BBszUFtVj8g3pu9bm7h"
if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${LRED}Correr con usuario ROOT${NC}"
    exit
fi 

echo "====================================="
apt-get update
echo -e "\n${LGREEN}El Servidor se encuentra Actualizado ...${NC}"

# Lista de paquetes a instalar
packages=("apache2" "php" "mariadb-server" "git" "curl")

# Funcion para verificar si un paquete esta  instalado
package_installed() {
    dpkg -l | grep -q $1
    return $?
}

# Instalar paquetes si no est      n instalados
for package in "${packages[@]}"
do
    if package_installed "$package"; then
        echo "$package ya est       instalado."
    else
        echo "Instalando $package..."
        apt install -y $package
        echo "$package instalado correctamente."
    fi
done
# Habilitar servicios y testear instalaci      n
echo "Habilitando servicios..."

# Habilitar servicios y testear instalaci      n
echo "Habilitando servicios..."
#sudo mysql_secure_installation
systemctl enable apache2
systemctl start mariadb.sevices
systemctl enable mariadb
systemctl enable php


# Instalar Modulo de PHP para Apache
apt install libapache2-mod-php -y 
apt install php-mysql -y
 
echo "Probando servicios..."
# Testear Apache
if systemctl is-active --quiet apache2; then
    echo "Apache esta funcionando correctamente."
else
    echo "Error: Apache no esta  funcionando correctamente."
fi

# Testear mariadb

if systemctl is-active --quiet mariadb; then

   echo "La base de datos esta funcionando correctamente."
else
   echo "Error: La base de datos No esta funcionando correctamente."
fi

php -v

echo "<?php phpinfo(); ?>" > /var/www/html/index.php

echo -e "\n${LBLUE}Configurando Base de Datos ...${NC}"

mysql -e "
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"

## Clonando Repositorio de la Apliación

if [ "$(ls | grep $repo)" = "$repo" ]; then
    echo "El repositorio de la Aplicación ya existe"
else
    echo "el repositorio de la Aplicación no esta clonado"
    echo "clonando..."
    git clone https://github.com/roxsross/$repo.git
    cd $repo
    git checkout clase2-linux-bash
fi

mv /var/www/html/index.html /var/www/html/index.hmtl.bkp
echo "moviendo app-295devops-travel a /var/www/html/"
mv app-295devops-travel /var/www/html/
### reload el servicio de Apache
systemctl reload apache2
##Ejecutando script de Estructuración de la Base de Datos 
mysql < /var/www/html/app-295devops-travel/database/devopstravel.sql

# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="http://localhost/app-295devops-travel/index.php"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1 | cut -d' ' -f2)

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    GRUPO="***Grupo 3***Ejercicio-1 Linux y Automatización"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio

# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION\n$GRUPO"

echo -e "\n${LBLUE}Enviando Notificación al Canal de Discord ...${NC}"  

# Envía el mensaje a Discord utilizando la API de Discord

echo $MESSAGE

curl -X POST -H "Content-Type: application/json" \
-d '{
       "content": "'"${MESSAGE}"'"
}' "$DISCORD"




