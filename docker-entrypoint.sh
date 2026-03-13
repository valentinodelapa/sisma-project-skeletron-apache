#!/bin/sh
set -e

# Sisma CLI
chmod +x /var/www/html/SismaFramework/Console/sisma 2>/dev/null || true

# Imposta i permessi sulle cartelle scrivibili
chown -R www-data:www-data /var/www/html/Cache /var/www/html/Logs /var/www/html/filesystemMedia 2>/dev/null || true
chmod -R 775 /var/www/html/Cache /var/www/html/Logs /var/www/html/filesystemMedia 2>/dev/null || true

exec "$@"
