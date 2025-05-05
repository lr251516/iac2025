#!/bin/bash

# Actualizar el sistema
yum update -y

# Instalar el servidor web Apache, PHP y MySQL
yum install -y httpd
amazon-linux-extras enable php5.6
yum clean metadata
yum install -y php php-common php-mysql php-gd php-xml php-mbstring php-mcrypt

# Instalar Git para clonar el repositorio
yum install -y git

# Iniciar y habilitar Apache
systemctl start httpd
systemctl enable httpd

# Limpiar el directorio web por defecto
rm -rf /var/www/html/*

# Clonar el repositorio de la aplicación web
git clone ${app_repo} /var/www/html/

# Configurar los parámetros de conexión a la base de datos
cat > /var/www/html/config.php << 'EOF'
<?php
define('DB_SERVER', '${db_host}');
define('DB_USERNAME', '${db_user}');
define('DB_PASSWORD', '${db_password}');
define('DB_DATABASE', '${db_name}');
?>
EOF

# Descargar y ejecutar el script SQL para crear la base de datos
cd /tmp
curl -O https://raw.githubusercontent.com/mauricioamendola/simple-ecomme/master/dump.sql
mysql -h ${db_host} -u ${db_user} -p${db_password} ${db_name} < /tmp/dump.sql

# Configurar permisos
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

# Reiniciar Apache para aplicar cambios
systemctl restart httpd

echo "Instalación completa" > /var/www/html/install_complete.txt