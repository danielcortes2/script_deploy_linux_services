# README - Script de Despliegue de Servicios Linux

## Descripción

Este script automatiza la configuración e instalación de varios servicios esenciales en servidores Linux, proporcionando opciones avanzadas para personalizar la configuración del sistema antes de la instalación estándar.

## Opciones del Menú de Configuración Avanzada

### 1. Configurar IP Estática

Permite establecer una dirección IP fija en el servidor en lugar de usar una asignación dinámica (DHCP). Esta co**nfiguración es opcional y sol**o está disponible si se elige esta opción en el menú. Está hecho para Ubuntu 24, probablemente si se utiliza otra distribución no funcione. Se solicitan los siguientes datos:

- Dirección IP
- Máscara de subred
- Puerta de enlace

El script genera un archivo de configuración en `/etc/netplan/01-netcfg.yaml` y aplica los cambios mediante `netplan apply`.

### 2. Configurar Servidor de Seguridad (fail2ban)

Instala y configura `fail2ban`, un servicio de protección contra ataques de fuerza bruta. Los pasos son:

1. Instalación de `fail2ban`.
2. Copia del archivo de configuración predeterminado a `jail.local`.
3. Modificación de parámetros:
   - Tiempo de baneo (`bantime`) aumentado a 1 hora.
   - Número máximo de intentos fallidos reducido a 3.
4. Reinicio del servicio `fail2ban` para aplicar los cambios.

### 3. Instalar Herramientas de Monitoreo

Instala las siguientes herramientas:

- **htop**: Monitor de procesos en tiempo real.
- **glances**: Supervisión de recursos del sistema.
- **netdata**: Panel web de monitoreo con información detallada de uso del sistema.

Se configura `netdata` para que solo acepte conexiones locales por seguridad y se reinicia su servicio.

### 4. Configurar Backup Automático

Automatiza la creación de copias de seguridad de configuraciones críticas y archivos web:

1. Crea el directorio `/backup`.
2. Instala `rsync` para la transferencia de archivos.
3. Genera un script en `/usr/local/bin/backup.sh` que copia:
   - Configuraciones del sistema (`/etc`).
   - Archivos de servidores web (`/var/www`).
4. Configura una tarea `cron` para ejecutar el backup diariamente a las 03:00 AM.

### 5. Continuar con la Instalación Estándar

Si el usuario elige continuar sin opciones avanzadas, el script realiza las siguientes tareas:

1. Actualiza el sistema (`apt update && apt upgrade`).
2. Configura el firewall (`ufw`) permitiendo solo conexiones seguras.
3. Instala y configura los siguientes servicios:
   - **Servidor NFS**: Para compartir archivos en red.
   - **SSHFS**: Para montaje seguro de archivos remotos.
   - **Servidor Apache**: Configura un servidor web con soporte para HTTPS.
   - **Servidor FTP**: Configura `vsftpd` para transferencia segura de archivos.
4. Reinicia los servicios y verifica su estado.

## Instalación y Uso

Para utilizar el script, sigue estos pasos:

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

## Requisitos

- Sistema Linux basado en Debian (preferiblemente Ubuntu 24.04).
- Acceso como usuario `root` o permisos `sudo`.
- Conexión a internet estable.

## Notas Adicionales

- Se recomienda revisar los archivos de configuración generados antes de reiniciar el sistema.
- Los logs del proceso se almacenan en `/var/log/server_setup.log`.

Este script proporciona una solución automatizada para la configuración inicial de servidores Linux, permitiendo personalización avanzada y seguridad desde el inicio.

