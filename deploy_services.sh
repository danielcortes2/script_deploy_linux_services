#!/usr/bin/env bash
################################################################################
# Script de despliegue automático de servicios en Linux:
#   - Evita Ctrl + C, Ctrl + \ y Ctrl + Z
#   - Verifica privilegios de root
#   - Pregunta si se purgan servicios ya instalados
#   - Solicita un nombre de dominio DNS para la configuración de BIND
#   - Detecta la IP actual del servidor y la utiliza en la zona DNS
#   - Instala y configura:
#       * Servidor NFS
#       * SSHFS (cliente)
#       * Servidor FTP (vsftpd)
#       * Servidor WEB (Apache)
#       * DNS con BIND9 (con la zona del dominio solicitado)
#       * Certificado autofirmado HTTPS (opcional)
#
# Probado en entornos Debian/Ubuntu. Ajustar según la distribución.
################################################################################

###############################################################################
# 1. Evitar salir con Ctrl + C, Ctrl + \ y Ctrl + Z
###############################################################################
trap '' SIGINT   # Ctrl + C
trap '' SIGQUIT  # Ctrl + \
trap '' SIGTSTP  # Ctrl + Z

###############################################################################
# 2. Verificar privilegios (root/sudo)
###############################################################################
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa sudo o inicia sesión como root."
  exit 1
fi

###############################################################################
# 3. Ofrecer purgar servicios antes de la instalación
###############################################################################
read -r -p "¿Deseas purgar NFS/FTP/Apache/BIND9 antes de instalar? (S/n): " PURGAR
if [[ "$PURGAR" =~ ^[Ss]$ ]]; then
    echo "Purgando servicios anteriores..."
    apt-get purge -y nfs-kernel-server vsftpd apache2 bind9
    apt-get autoremove -y
    apt-get autoclean
    echo "Paquetes y configuraciones relacionadas purgadas."
else
    echo "ADVERTENCIA: Podrían quedar configuraciones previas."
    read -r -p "¿Estás seguro de continuar sin purgar? (S/n): " CONTINUAR
    if [[ ! "$CONTINUAR" =~ ^[Ss]$ ]]; then
        echo "Saliendo del script..."
        exit 1
    fi
    echo "Continuando sin purgar servicios..."
fi

###############################################################################
# 4. Pedir nombre de dominio DNS
###############################################################################
read -r -p "Introduce el nombre de dominio que deseas configurar (ej. example.local): " DOMINIO
if [ -z "$DOMINIO" ]; then
  DOMINIO="example.local"
  echo "No se introdujo un dominio. Se usará '$DOMINIO' por defecto."
fi

###############################################################################
# Obtener la IP actual del servidor para usarla en el DNS
###############################################################################
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
  # Fallback, en caso de no detectar IP con hostname -I
  HOST_IP="127.0.0.1"
fi
echo "IP detectada: $HOST_IP"

###############################################################################
# 5. Actualizar repositorios e instalar paquetes básicos
###############################################################################
echo "=== Actualizando repositorios e instalando paquetes base ==="
apt-get update -y
apt-get upgrade -y
apt-get install -y git curl wget

###############################################################################
# 6. Instalar y configurar Servidor NFS
###############################################################################
echo "=== Instalando y configurando NFS Server ==="
apt-get install -y nfs-kernel-server

read -r -p "Introduce la red que puede acceder a NFS (ej. 192.168.1.0/24): " NFS_RED
if [ -z "$NFS_RED" ]; then
  NFS_RED="192.168.1.0/24"
  echo "No se introdujo una red, se usará '$NFS_RED' por defecto."
fi

NFS_DIR="/srv/nfs_share"
mkdir -p "${NFS_DIR}"
chown nobody:nogroup "${NFS_DIR}"
chmod 777 "${NFS_DIR}"
echo "${NFS_DIR}  ${NFS_RED}(rw,sync,no_subtree_check)" >> /etc/exports
exportfs -ra
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
echo "NFS configurado. Carpeta exportada: ${NFS_DIR} (acceso desde ${NFS_RED})"

###############################################################################
# 7. Instalar SSHFS (para pruebas)
###############################################################################
echo "=== Instalando SSHFS (cliente) ==="
apt-get install -y sshfs
echo "SSHFS instalado. Para usarlo: sshfs usuario@host_remoto:/ruta /punto/de/montaje"

###############################################################################
# 8. Instalar y configurar Servidor FTP (vsftpd)
###############################################################################
echo "=== Instalando y configurando vsftpd (FTP) ==="
apt-get install -y vsftpd
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
sed -i 's/^#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
sed -i 's/^anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
systemctl enable vsftpd
systemctl restart vsftpd
echo "vsftpd instalado y configurado."

###############################################################################
# 9. Instalar y configurar Servidor Web Apache
###############################################################################
echo "=== Instalando y configurando Apache ==="
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
echo "<h1>Servidor Apache funcionando con dominio: $DOMINIO</h1>" > /var/www/html/index.html

###############################################################################
# 10. Instalar y configurar DNS con BIND9
###############################################################################
echo "=== Instalando BIND9 (DNS) ==="
apt-get install -y bind9

cat <<EOF >> /etc/bind/named.conf.local

zone "$DOMINIO" {
  type master;
  file "/etc/bind/db.$DOMINIO";
};
EOF

cp /etc/bind/db.local /etc/bind/db.$DOMINIO
sed -i "s/localhost/$DOMINIO./g" /etc/bind/db.$DOMINIO
sed -i "s/127.0.0.1/$HOST_IP/g" /etc/bind/db.$DOMINIO
sed -i "s/::1/::1/g" /etc/bind/db.$DOMINIO
sed -i "s/ root.$DOMINIO./ admin.$DOMINIO./" /etc/bind/db.$DOMINIO
sed -i "s/ serial/ 2/" /etc/bind/db.$DOMINIO
systemctl enable bind9
systemctl restart bind9
echo "BIND9 instalado. Zona para $DOMINIO configurada en /etc/bind/db.$DOMINIO"
echo "Se está usando la IP $HOST_IP"

###############################################################################
# 11. (Opcional) Certificado autofirmado para Apache
###############################################################################
read -r -p "¿Deseas generar un certificado SSL autofirmado para Apache? (S/n): " GENERAR_SSL
if [[ "$GENERAR_SSL" =~ ^[Ss]$ ]]; then
  echo "=== Generando certificado SSL autofirmado para $DOMINIO ==="
  apt-get install -y openssl
  SSL_DIR="/etc/apache2/ssl"
  mkdir -p "${SSL_DIR}"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${SSL_DIR}/selfsigned.key" \
    -out "${SSL_DIR}/selfsigned.crt" \
    -subj "/C=ES/ST=TuProvincia/L=TuCiudad/O=TuOrganizacion/OU=IT/CN=${DOMINIO}"
  a2enmod ssl
  cat <<EOF > /etc/apache2/sites-available/ssl.conf
<VirtualHost *:443>
    ServerAdmin admin@$DOMINIO
    ServerName $DOMINIO
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile    ${SSL_DIR}/selfsigned.crt
    SSLCertificateKeyFile ${SSL_DIR}/selfsigned.key

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
EOF
  a2ensite ssl.conf
  systemctl restart apache2
  echo "Certificado SSL autofirmado configurado. Puedes acceder a https://$DOMINIO"
else
  echo "No se generará certificado SSL, se continuará con HTTP."
fi

###############################################################################
# 12. Final
###############################################################################
echo "========================================================================="
echo "FIN DEL SCRIPT: Servicios instalados y configurados."
echo "- NFS: carpeta exportada en ${NFS_DIR} para la red ${NFS_RED}"
echo "- SSHFS instalado."
echo "- vsftpd, Apache y BIND9 configurados."
echo "- Dominio DNS: $DOMINIO resolviendo a $HOST_IP"
echo "- Si has generado certificado, HTTPS activo en puerto 443."
echo "========================================================================="
