# Changelog

## [1.0.4] - 2026-03-19

### Modificato
- Workflow di release: rimosso il remote `origin` dalla repository inclusa nell'archivio ZIP, in modo che non punti allo skeleton
- Workflow di release: aggiunto `--exclude=".github/*"` per escludere la cartella `.github/` dall'archivio ZIP

## [1.0.3] - 2026-03-19

### Modificato
- Rimossi gli `--exclude` per i file git (`*.git*`, `*.github*`, `.gitattributes`, `.gitignore`) dal workflow di release, in modo che vengano inclusi nell'archivio ZIP generato

## [1.0.2] - 2026-03-15

### Modificato
- Rimossa la direttiva `zend_extension=xdebug` da `xdebug.ini` (l'estensione è già abilitata via `docker-php-ext-enable` nel Dockerfile)

## [1.0.1] - 2026-03-14

### Modificato
- Configurazione Xdebug agnostica rispetto all'IDE (`idekey=XDEBUG`)

## [1.0.0] - 2026-03-12

### Aggiunto
- Configurazione iniziale dello skeleton con server web Apache (PHP 8.5)
- Estensioni PHP: mysqli, pdo_mysql, zip, pcov, xdebug
- Supporto a Composer
- Configurazione Xdebug (modalità trigger, host.docker.internal)
- Sisma CLI disponibile come eseguibile nel PATH
- Stack Docker Compose: Apache+PHP, MariaDB, phpMyAdmin
- Integrazione con Traefik per lo sviluppo locale
- `docker-entrypoint.sh` per la gestione dei permessi a runtime
- Inizializzazione MariaDB: utf8mb4, root con accesso completo, db_user con soli permessi DML
