# Changelog

## [1.5.0] - 2026-06-27

### Aggiunto
- `.env.example`: nuovo file di esempio per le variabili d'ambiente (credenziali database, passphrase di cifratura), da copiare in `.env` (non versionato, escluso da `.gitignore`)
- `docker-compose.yml`: il servizio `app` monta `.env` tramite `env_file`, rendendo le variabili disponibili a SismaFramework via `getenv()`
- `setup.sh`: genera automaticamente `.env` da `.env.example` con i valori raccolti interattivamente, incluso una passphrase di cifratura generata casualmente, prima dell'avvio dei container

### Modificato
- `docker-compose.yml`: i servizi `db` e `phpmyadmin` leggono le credenziali da variabili `${...}` (popolate da `.env`) invece di valori letterali, eliminando le credenziali in chiaro dal file committato
- `setup.sh`: rimossa la sostituzione delle credenziali direttamente in `docker-compose.yml` (ora gestita tramite `.env`); rimosso il promemoria "se l'installer chiede le credenziali, usa questi valori" — non più necessario, l'installer le rileva automaticamente dall'ambiente
- `README.md`: aggiornato il "Metodo manuale" e la sezione "Credenziali database" per riflettere il nuovo flusso basato su `.env`

### Aggiornato
- SismaFramework aggiornato alla versione `11.9.0`

### Migrazione necessaria
- Il "Metodo manuale" richiede ora un passaggio aggiuntivo: copiare `.env.example` in `.env` e compilarlo prima di `docker compose up -d`. Senza `.env`, l'avvio dei container fallisce (`env_file` non trovato). Il "Metodo automatico" (`setup.sh`) non richiede alcuna azione aggiuntiva: genera `.env` automaticamente.

## [1.4.0] - 2026-06-18

### Aggiunto
- `setup.sh`: prima di eseguire `sisma install` viene ora chiesto se passare l'opzione `--module=<nome>` al comando, per limitare l'esecuzione al modulo specificato

### Aggiornato
- SismaFramework aggiornato alla versione `11.7.0`

## [1.3.1] - 2026-06-18

### Corretto
- `setup.sh`: i sottomoduli Git vengono ora aggiunti e inizializzati prima dell'avvio di Docker (step 6), in modo che siano disponibili al momento dell'esecuzione di `sisma install`; in precedenza venivano aggiunti dopo `composer install`, rendendo le estensioni dei sottomoduli invisibili all'installer

## [1.3.0] - 2026-06-17

### Aggiunto
- `setup.sh`: supporto a sottomoduli Git opzionali in `www/`; durante il setup viene chiesto se aggiungere sottomoduli, con raccolta interattiva di URL e nome cartella, validazione e deduplicazione; i sottomoduli vengono aggiunti e inizializzati al termine dell'installazione

## [1.2.3] - 2026-06-17

### Aggiornato
- SismaFramework aggiornato alla versione `11.6.3`

## [1.2.2] - 2026-06-16

### Corretto
- `setup.sh`: `composer install` ora eseguito tramite `bash -c "cd /var/www/html && composer install"` nel container; il flag `-w` di `docker exec` veniva anch'esso convertito da Git Bash/MSYS2 in percorso Windows, causando l'errore `Cwd must be an absolute path`

## [1.2.1] - 2026-06-16

### Corretto
- `setup.sh`: `composer install` ora usa `docker exec -w /var/www/html` invece di `--working-dir`; il flag `--working-dir` veniva espanso dalla shell host e su Git Bash/MSYS2 il path veniva tradotto in percorso Windows (`C:/Program Files/Git/var/www/html`)

## [1.2.0] - 2026-06-16

### Aggiunto
- `setup.sh`: esecuzione automatica di `composer install` in `/var/www/html/` al termine di `sisma install`

## [1.1.6] - 2026-06-16

### Corretto
- `setup.sh`: rilevamento dell'ambiente Git Bash / MSYS2 tramite variabile `MSYSTEM` per la gestione del flag TTY di `docker exec`; usa `-i` su Git Bash (dove l'allocazione TTY non è supportata da Docker), `-it` negli altri ambienti

## [1.1.5] - 2026-06-16

### Corretto
- `setup.sh`: rilevamento automatico del TTY per `docker exec`; usa `-it` se stdin è un terminale reale, `-i` altrimenti (compatibilità con Git Bash e ambienti non-TTY)

## [1.1.4] - 2026-06-15

### Corretto
- `setup.sh`: rimosso il passaggio di aggiornamento di `composer.json`, non presente nell'archivio di release; riallineati i numeri dei passi

## [1.1.3] - 2026-06-08

### Corretto
- Workflow di release: la repository vergine nell'archivio ZIP include ora SismaFramework correttamente registrato come sottomodulo; il primo commit viene creato da `setup.sh` al termine del setup, usando l'identità git dell'utente
- `setup.sh`: rimossa l'inizializzazione git (già gestita dal workflow); il commit finale usa il repo già inizializzato

## [1.1.2] - 2026-06-05

### Corretto
- Workflow di release: l'archivio ZIP non include più la directory `.git`; la repository viene inizializzata da `setup.sh` al termine del setup, con un "Initial commit" che cattura il progetto già configurato
- `setup.sh`: aggiunta inizializzazione della repository git e creazione del primo commit al termine del setup

## [1.1.1] - 2026-06-05

### Corretto
- Workflow di release: la repository inclusa nell'archivio ZIP è ora vergine (singolo "Initial commit"), senza la history dei commit dello skeleton

## [1.1.0] - 2026-06-04

### Aggiunto
- `setup.sh`: script interattivo per l'inizializzazione automatica del progetto (rinomina file, aggiornamento credenziali, avvio Docker, esecuzione `sisma install`)
- `README.md`: documentata la procedura di setup automatico tramite `setup.sh` in alternativa al metodo manuale

## [1.0.5] - 2026-04-12

### Corretto

- `docker-compose.yml`: aggiunto `user: root` al servizio `app` per garantire i permessi di scrittura sulle cartelle montate da Windows

## [1.0.5] - 2026-03-27

### Corretto
- `docker-entrypoint.sh`: convertiti i fine riga da CRLF a LF per compatibilità con i container Linux
- `skeletron_apache.sql`: rimossa la `REVOKE ALL PRIVILEGES` su `db_user`, non necessaria poiché MariaDB non assegna privilegi di default sullo schema

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
