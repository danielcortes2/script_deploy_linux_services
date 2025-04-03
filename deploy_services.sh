#!/bin/bash

# Script de Configuración de Servidor Linux Ubuntu 24.04

# Variables globales para registro de log
LOG_FILE="/var/log/server_setup.log"
INICIO=$(date +"%Y-%m-%d %H:%M:%S")

# Función de registro de log
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $*" | tee -a "$LOG_FILE"
}

# Función de manejo de errores
error_handler() {
    local linea=$1
    local comando=$2
    log "ERROR: Comando '$comando' falló en la línea $linea"
    
    # Enviar notificación por correo (requiere configuración de postfix)
    echo "Error durante la configuración del servidor" | mail -s "Instalación de Servidor - Error" root
    
    exit 1
}

# Trap para capturar errores
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

# Función para mostrar mensaje de bienvenida
mostrar_bienvenida() {
    echo "==============================================="
    echo "   Script de Configuración de Servidor Linux   "
    echo "==============================================="
}

# Función para purgar paquetes
purgar_paquetes() {
    read -p "¿Desea realizar una purga completa de paquetes? (s/n): " purgar_resp

    if [[ "$purgar_resp" =~ ^[Ss]$ ]]; then
        log "Purgando paquetes instalados..."
        
        # Servicios a purgar
        servicios_a_purgar=(
            "apache2"
            "vsftpd"
            "nfs-kernel-server"
            "bind9"
            "sshfs"
        )

        for servicio in "${servicios_a_purgar[@]}"; do
            log "Purgando $servicio..."
            systemctl stop "$servicio" 2>/dev/null
            apt-get purge -y "$servicio"*
        done

        # Limpiar paquetes huérfanos
        apt-get autoremove -y
        apt-get autoclean

        log "Purga de paquetes completada."
    else
        log "Continuando sin purgar paquetes."
    fi
}

# Función para verificar requisitos del sistema
verificar_requisitos() {
    log "Verificando requisitos del sistema..."
    
    # Verificar versión de Ubuntu
    . /etc/os-release
    if [[ "$VERSION_CODENAME" != "noble" ]]; then
        log "ADVERTENCIA: Este script está optimizado para Ubuntu 24.04 (Noble Numbat)"
    fi

    # Verificar espacio en disco
    ESPACIO_DISPONIBLE=$(df -h / | awk '/\// {print $4}' | sed 's/G//')
    if (( $(echo "$ESPACIO_DISPONIBLE < 10" | bc -l) )); then
        log "ADVERTENCIA: Espacio en disco bajo. Se recomienda al menos 10GB libres."
    fi

    # Verificar RAM
    MEMORIA_TOTAL=$(free -g | awk '/^Mem:/ {print $2}')
    if (( MEMORIA_TOTAL < 2 )); then
        log "ADVERTENCIA: Memoria RAM baja. Se recomiendan al menos 2GB."
    fi
}

# Función para solicitar configuración personalizada
solicitar_configuracion() {
    # Solicitar nombre de dominio DNS
    while true; do
        read -p "Introduce el nombre de dominio DNS (ej: midominio.local): " DOMINIO_DNS
        if [[ -n "$DOMINIO_DNS" ]]; then
            break
        else
            echo "El nombre de dominio no puede estar vacío."
        fi
    done

    # Solicitar contenido de página web
    read -p "Introduce el título para tu página web: " TITULO_WEB
    TITULO_WEB="${TITULO_WEB:-Bienvenido a mi Servidor}"

    read -p "Introduce un mensaje de bienvenida para tu página web: " MENSAJE_WEB
    MENSAJE_WEB="${MENSAJE_WEB:-Este es mi nuevo servidor Linux}"
}

# Nueva función para instalar paquetes adicionales
instalar_paquetes_adicionales() {
    log "Instalando paquetes adicionales..."
    
    # Añadir repositorio para Visual Studio Code
    if ! grep -q "packages.microsoft.com/repos/code" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        log "Añadiendo repositorio de Visual Studio Code..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        apt update
    fi
    
    # Paquetes a instalar
    log "Instalando micro, Visual Studio Code, tree, neofetch, htop y ncdu..."
    apt install -y micro code tree neofetch htop ncdu
    
    # Verificar instalación
    paquetes_instalados=()
    for paquete in micro code tree neofetch htop ncdu; do
        if dpkg -l | grep -q $paquete; then
            paquetes_instalados+=("$paquete")
        else
            log "ADVERTENCIA: No se pudo instalar $paquete"
        fi
    done
    
    log "Paquetes instalados correctamente: ${paquetes_instalados[*]}"
    echo "Paquetes adicionales instalados. Presione Enter para continuar."
    read
}

# Función para instalar y configurar SSH
instalar_configurar_ssh() {
    log "Instalando y configurando servidor SSH..."
    
    # Instalar servidor SSH
    apt install -y openssh-server
    
    # Hacer copia de seguridad del archivo de configuración original
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Configuraciones de seguridad básicas
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # Reiniciar servicio SSH
    systemctl restart ssh
    systemctl enable ssh
    
    # Configurar firewall para SSH
    ufw allow ssh
    
    log "Servidor SSH instalado y configurado"
    echo "Servidor SSH instalado y configurado. Presione Enter para continuar."
    read
}

# Función de menú de configuración avanzada
menu_configuracion_avanzada() {
    while true; do
        clear
        echo "===== Configuración Avanzada de Servidor ====="
        echo "1. Instalar Paquetes Adicionales"
        echo "2. Configurar servidor de seguridad adicional (fail2ban)"
        echo "3. Instalar herramientas de monitoreo"
        echo "4. Configurar backup automático"
        echo "5. Instalar y configurar SSH"
        echo "6. Continuar con instalación estándar"
        echo "7. Salir del menú"
        
        read -p "Seleccione una opción (1-7): " opcion_avanzada
        
        case $opcion_avanzada in
            1) instalar_paquetes_adicionales ;;
            2) configurar_fail2ban ;;
            3) instalar_monitoreo ;;
            4) configurar_backup ;;
            5) instalar_configurar_ssh ;;
            6) break ;;
            7) echo "Saliendo del menú de configuración avanzada..."; exit 0 ;;
            *) echo "Opción inválida. Presione Enter para continuar."; read ;;
        esac
    done
}

# Configuración de fail2ban
configurar_fail2ban() {
    apt install -y fail2ban
    
    # Configuración básica para SSH y Apache
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sed -i 's/bantime  = 10m/bantime  = 1h/' /etc/fail2ban/jail.local
    sed -i 's/maxretry = 5/maxretry = 3/' /etc/fail2ban/jail.local

    systemctl restart fail2ban
    log "Fail2ban instalado y configurado"
}

# Instalar herramientas de monitoreo
instalar_monitoreo() {
    apt install -y htop glances netdata
    
    # Configuración básica de Netdata
    sed -i 's/# bind to = \*/bind to = 127.0.0.1/' /etc/netdata/netdata.conf
    systemctl restart netdata
    
    log "Herramientas de monitoreo instaladas: htop, glances, netdata"
}

# Configuración de backup automático
configurar_backup() {
    # Crear directorio de backups
    mkdir -p /backup

    # Instalar herramienta de backup
    apt install -y rsync

    # Crear script de backup
    cat > /usr/local/bin/backup.sh << 'EOL'
#!/bin/bash
BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Backup de configuraciones críticas
rsync -avz /etc $BACKUP_DIR/etc_backup_$TIMESTAMP
rsync -avz /var/www $BACKUP_DIR/web_backup_$TIMESTAMP

# Eliminar backups antiguos (más de 30 días)
find $BACKUP_DIR -type d -mtime +30 -exec rm -rf {} \;
EOL

    # Hacer el script ejecutable
    chmod +x /usr/local/bin/backup.sh

    # Configurar cron para backup diario
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/backup.sh") | crontab -

    log "Configuración de backup automático completada"
}

# Actualizar sistema
update_system() {
    log "Actualizando sistema..."
    apt update && apt upgrade -y
    apt install -y software-properties-common
}

# Configurar Firewall (UFW)
configurar_firewall() {
    log "Configurando Firewall UFW..."
    ufw enable
    ufw default deny incoming
    ufw default allow outgoing
}

# Configurar Servidor NFS
configurar_nfs() {
    log "Instalando y configurando Servidor NFS..."
    
    # Instalar paquetes NFS
    apt install -y nfs-kernel-server

    # Crear directorio para compartir
    mkdir -p /export/shared
    
    # Configurar permisos
    chown nobody:nogroup /export/shared
    chmod 755 /export/shared

    # Configurar exports
    echo "/export/shared *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

    # Reiniciar servicio NFS
    systemctl restart nfs-kernel-server
    systemctl enable nfs-kernel-server

    # Configurar firewall para NFS
    ufw allow from any to any port 2049
}

# Configurar SSHFS y Servidor FTP
configurar_ssh_ftp() {
    log "Instalando SSHFS y Servidor FTP (vsftpd)..."
    
    # Instalar SSHFS y vsftpd
    apt install -y sshfs vsftpd

    # Configuración de vsftpd
    sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
    sed -i 's/#local_enable=YES/local_enable=YES/' /etc/vsftpd.conf
    sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf

    # Reiniciar servicios
    systemctl restart vsftpd
    systemctl enable vsftpd

    # Configurar firewall
    ufw allow 20/tcp  # FTP datos
    ufw allow 21/tcp  # FTP control
}

# Configurar Servidor Web Apache
configurar_apache() {
    log "Instalando y configurando Apache..."
    
    # Instalar Apache y módulos
    apt install -y apache2 apache2-utils

    # Generar certificado autofirmado
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/apache-selfsigned.key \
        -out /etc/ssl/certs/apache-selfsigned.crt \
        -subj "/C=ES/ST=MiEstado/L=MiCiudad/O=MiOrganizacion/OU=MiUnidad/CN=$DOMINIO_DNS"

    # Habilitar módulos SSL
    a2enmod ssl
    a2enmod rewrite

    # Configuración básica de sitio HTTPS
    cat > /etc/apache2/sites-available/default-ssl.conf << EOL
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ServerName ${DOMINIO_DNS}
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>
EOL

    # Habilitar sitio SSL
    a2ensite default-ssl

    # Reiniciar Apache
    systemctl restart apache2
    systemctl enable apache2

    # Configurar firewall
    ufw allow 'Apache Full'
}

# Configurar DNS (Bind9)
configurar_dns() {
    log "Instalando y configurando Servidor DNS Bind9..."
    
    # Obtener IP del servidor automáticamente
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    local OCTETOS=(${SERVER_IP//./ })
    local NETWORK="${OCTETOS[0]}.${OCTETOS[1]}.${OCTETOS[2]}"
    local REVERSE_ZONE="${OCTETOS[2]}.${OCTETOS[1]}.${OCTETOS[0]}.in-addr.arpa"

    log "IP del servidor detectada: $SERVER_IP"

    # Instalar Bind9
    apt install -y bind9 bind9utils bind9-doc

    # Configuración avanzada de named.conf.local
    cat > /etc/bind/named.conf.local << EOL
// Configuración de zonas para $DOMINIO_DNS

// Zona directa
zone "${DOMINIO_DNS}" IN {
    type master;
    file "/etc/bind/zones/db.${DOMINIO_DNS}";
    allow-update { none; };
};

// Zona inversa
zone "${REVERSE_ZONE}" IN {
    type master;
    file "/etc/bind/zones/db.${NETWORK}.rev";
    allow-update { none; };
};
EOL

    # Crear directorio para archivos de zona
    mkdir -p /etc/bind/zones

    # Configuración de zona directa
    cat > "/etc/bind/zones/db.${DOMINIO_DNS}" << EOL
\$TTL    86400
@       IN      SOA     ${DOMINIO_DNS}. admin.${DOMINIO_DNS}. (
                  $(date +%Y%m%d%H)  ; Serial
             86400     ; Refresh
              3600     ; Retry
            2419200    ; Expire
              86400 )  ; Negative Cache TTL

; Servidores de nombres
@       IN      NS      ${DOMINIO_DNS}.

; Definición de registros
@       IN      A       ${SERVER_IP}
www     IN      CNAME   @

; Registros adicionales si es necesario
$(hostname) IN A ${SERVER_IP}
EOL

    # Configuración de zona inversa
    cat > "/etc/bind/zones/db.${NETWORK}.rev" << EOL
\$TTL    86400
@       IN      SOA     ${DOMINIO_DNS}. admin.${DOMINIO_DNS}. (
                  $(date +%Y%m%d%H)  ; Serial
             86400     ; Refresh
              3600     ; Retry
            2419200    ; Expire
              86400 )  ; Negative Cache TTL

; Servidores de nombres
@       IN      NS      ${DOMINIO_DNS}.

; Mapeo de IP a nombre
${OCTETOS[3]}      IN      PTR     ${DOMINIO_DNS}.
${OCTETOS[3]}      IN      PTR     $(hostname).${DOMINIO_DNS}.
EOL

    # Configuración de named.conf.options con más seguridad
    cat > /etc/bind/named.conf.options << EOL
options {
    directory "/var/cache/bind";
    
    // Restringir recursión y consultas
    recursion yes;
    allow-recursion { 
        localhost; 
        localnets; 
    };
    
    // Servidores de reenvío
    forwarders {
        8.8.8.8;
        1.1.1.1;
    };
    
    // Mejoras de seguridad
    dnssec-validation auto;
    auth-nxdomain no;    # Cumplir con RFC1035
    listen-on-v6 { any; };
    
    // Prevenir DNS amplification attacks
    rate-limit {
        responses-per-second 10;
    };
};
EOL

    # Configurar permisos
    chown -R bind:bind /etc/bind/zones
    chmod 644 /etc/bind/zones/*

    # Validar configuración
    named-checkconf /etc/bind/named.conf
    named-checkzone "$DOMINIO_DNS" "/etc/bind/zones/db.${DOMINIO_DNS}"
    named-checkzone "$REVERSE_ZONE" "/etc/bind/zones/db.${NETWORK}.rev"

    # Reiniciar servicio DNS
    systemctl restart named
    systemctl enable named

    # Configurar firewall
    ufw allow 53/tcp
    ufw allow 53/udp

    log "Configuración de DNS completada para $DOMINIO_DNS con IP $SERVER_IP"
}

# Crear página web personalizada
crear_pagina_web() {
    cat > /var/www/html/index.html << EOL
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>${TITULO_WEB}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
            text-align: center;
        }
        h1 {
            color: #333;
        }
        p {
            color: #666;
        }
    </style>
</head>
<body>
    <h1>${TITULO_WEB}</h1>
    <p>${MENSAJE_WEB}</p>
    <footer>
        <small>Servidor configurado automáticamente</small>
    </footer>
</body>
</html>
EOL
}

# Función para reiniciar servicios
reiniciar_servicios() {
    log "Reiniciando todos los servicios instalados..."
    
    # Servicios a reiniciar
    servicios=(
        "nfs-kernel-server"
        "vsftpd"
        "apache2"
        "named"
        "fail2ban"
        "netdata"
        "ssh"
    )

    for servicio in "${servicios[@]}"; do
        if systemctl is-active --quiet "$servicio"; then
            systemctl restart "$servicio"
            log "Reiniciando $servicio"
        fi
    done
}

# Función principal
main() {
    # Verificar que se ejecute como root
    if [[ $EUID -ne 0 ]]; then
       log "Este script debe ejecutarse como root (usar sudo)" 
       exit 1
    fi

    log "Iniciando configuración de servidor..."
    
    # Verificar requisitos del sistema
    verificar_requisitos
    
    # Menú de configuración avanzada
    menu_configuracion_avanzada

    # Resto de la configuración...
    mostrar_bienvenida
    purgar_paquetes
    solicitar_configuracion

    update_system
    configurar_firewall
    configurar_nfs
    configurar_ssh_ftp
    configurar_apache
    configurar_dns
    crear_pagina_web
    
    # Añadir reinicio de servicios al final
    reiniciar_servicios

    # Finalizar instalación
    log "Instalación completada en $INICIO"
    echo "Instalación completada. Consulte el log en $LOG_FILE"
}

# Ejecutar instalación
main
