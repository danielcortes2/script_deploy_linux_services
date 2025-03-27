# Script de Despliegue de Servicios Linux

## Descripción
Este script automatiza la configuración e instalación de varios servicios esenciales para servidores Linux, incluyendo:
- Servicio NFS (Network File System) con configuración segura
- SSHFS (SSH Filesystem)
- Servidor Apache con resolución DNS 
- Certificado HTTPS
- Servidor FTP

## Requisitos Previos
- Sistema operativo Linux (preferiblemente distribuciones basadas en Debian/Ubuntu)
- Acceso a sudo o como usuario root
- Conexión a internet
- Conocimientos básicos de administración de sistemas Linux

## Configuración Inicial de Git

### Configuración de Identidad de Git
Antes de usar el script, configura tu identidad de Git para los commits:

```bash
# Establece el nombre de usuario que aparecerá en tus commits
git config --global user.name "Tu Nombre"

# Establece el correo electrónico que aparecerá en tus commits
git config --global user.email "tu_correo@example.com"
```

## Servicios Incluidos

### 1. NFS (Network File System)
- Configuración segura de compartición de archivos en red
- Control de permisos y acceso
- Optimización de rendimiento

### 2. SSHFS
- Montaje de sistemas de archivos remotos via SSH
- Conexiones seguras
- Fácil acceso a directorios remotos

### 3. Servidor Apache
- Configuración de servidor web
- Resolución DNS automática
- Instalación de certificado HTTPS
- Configuración de seguridad básica

### 4. Servidor FTP
- Configuración de servidor de transferencia de archivos
- Soporte para conexiones seguras
- Gestión de usuarios y permisos

## Instalación

```bash
# Clonar el repositorio
git clone https://github.com/tu_usuario/script_deploy_linux_services.git

# Cambiar al directorio del script
cd script_deploy_linux_services

# Dar permisos de ejecución
chmod +x script_instalacion.sh

# Ejecutar el script
sudo ./script_instalacion.sh
```

## Personalización
Antes de ejecutar el script, revisa y modifica los siguientes archivos de configuración según tus necesidades:
- `config/nfs_config.conf`
- `config/apache_config.conf`
- `config/ftp_config.conf`

## Seguridad
- Utiliza contraseñas seguras
- Configura firewalls
- Mantén el sistema actualizado
- Revisa y ajusta los permisos de acceso

## Solución de Problemas
- Verifica los logs de sistema en `/var/log/`
- Comprueba la configuración de los servicios
- Asegúrate de tener los permisos necesarios

## Contribuciones
Las contribuciones son bienvenidas. Por favor, abre un issue o envía un pull request.
