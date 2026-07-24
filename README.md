# SismaSkeletronApache

[![PHP Version Support](https://img.shields.io/badge/php-%3E%3D8.5-blue)](https://www.php.net/)
[![license](https://img.shields.io/badge/license-MIT-yellowgreen)](https://github.com/valentinodelapa/sisma-project-skeletron-apache/blob/master/LICENSE)
[![SLSA 3](https://img.shields.io/badge/SLSA-Level%203-blue)](https://slsa.dev/spec/v0.1/levels#level-3)

Skeleton Docker per progetti basati su SismaFramework con server web Apache.

## Stack

*   **PHP 8.5** con modulo Apache (`php:8.5-apache`)
*   **MariaDB** (ultima versione)
*   **phpMyAdmin** per la gestione del database (solo sviluppo)
*   **Mailpit** come mock SMTP per intercettare la posta in uscita (solo sviluppo)
*   **Traefik** come reverse proxy per lo sviluppo locale

## Prerequisiti

*   Docker e Docker Compose
*   Per lo sviluppo: Traefik in esecuzione sulla rete esterna `web_network` (non richiesto in produzione, vedi "Esposizione in produzione")

## Ambienti: sviluppo e produzione

La configurazione Docker è divisa in tre file:

| File                        | Contenuto                                                        |
|-----------------------------|-------------------------------------------------------------------|
| `docker-compose.yml`        | servizi core (`app` + `db`), comuni a ogni ambiente. `db` è dietro il profilo `internal-db` (vedi "Database interno o esterno") |
| `docker-compose.dev.yml`    | aggiunte per lo sviluppo: esposizione di `app` via Traefik (`web_network`, dominio `.localhost`), `phpmyadmin`, `mailpit` (mock SMTP) |
| `docker-compose.prod.yml`   | aggiunte per la produzione: `restart: unless-stopped` sui servizi core (esposizione pubblica da configurare a parte, vedi sezione dedicata) |
| `docker-compose.backup.yml` | layer opzionale: backup schedulato del database (vedi sezione dedicata) |

Il `Makefile` evita di scrivere per esteso il comando con i vari `-f`:

```bash
make start-dev              # docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile internal-db up -d
make stop-dev                # docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile internal-db down
make start-prod              # docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile internal-db up -d
make stop-prod                # docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile internal-db down
make start-prod-external-db  # docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
make stop-prod-external-db   # docker compose -f docker-compose.yml -f docker-compose.prod.yml down
make start-backup            # docker compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.backup.yml --profile internal-db up -d
make stop-backup             # docker compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.backup.yml --profile internal-db down
```

I target `*-external-db` avviano lo stack senza il servizio `db` interno: usarli quando il database è gestito esternamente (RDS, MariaDB/MySQL managed, ecc.), puntando `DATABASE_HOST`/`DATABASE_PORT` in `.env` all'endpoint reale.

## Avvio (sviluppo)

```bash
cp .env.example .env
make start-dev
```

L'applicazione sarà disponibile su `http://skeletron-apache.localhost`, phpMyAdmin su `http://db.skeletron-apache.localhost` e Mailpit su `http://mail.skeletron-apache.localhost`.

## Credenziali database

Le credenziali (e la passphrase di cifratura) sono lette dal file `.env` (non versionato, copiato da `.env.example`), che `docker-compose.yml` rende disponibile ai container tramite `env_file`. Senza `.env`, l'avvio dei container fallisce.

| Parametro       | Valore di default (`.env.example`) |
|-----------------|-------------------------------------|
| Host            | `db`               |
| Database        | `skeletron_apache` |
| Utente          | `db_user`          |
| Password        | `change_me_db_password` |
| Password root   | `change_me_root_password` |

## Database interno o esterno

Il servizio `db` (container MariaDB) è dietro il profilo Compose `internal-db`, non attivo di default. Due scenari:

*   **Database interno** (container MariaDB gestito da questo stack): usare i target Make standard (`start-dev`, `start-prod`, `start-backup`), che attivano il profilo con `--profile internal-db`. È il comportamento di sempre, invariato.
*   **Database esterno** (gestito, es. RDS, MariaDB/MySQL managed, un server dedicato): usare `make start-prod-external-db` / `make stop-prod-external-db`, che avviano lo stack senza il container `db`. In questo caso in `.env` vanno impostati `DATABASE_HOST`/`DATABASE_PORT` con l'endpoint reale (e le credenziali fornite dal provider) — l'applicativo li legge comunque da lì, nessuna modifica al codice.

`phpMyAdmin` (solo sviluppo) è anch'esso dietro `internal-db`, dato che punta al container `db`: non ha senso con un database esterno in dev; per lo sviluppo si assume comunque database interno.

Il servizio `backup` (`docker-compose.backup.yml`) **non** dipende dal container `db`: esegue `mariadb-dump` contro `DATABASE_HOST` letto da `.env`, quindi funziona invariato anche puntando a un database esterno, a patto di avere le credenziali root necessarie al dump (il target `make start-backup` attiva comunque il profilo `internal-db` perché il caso d'uso più comune è il backup del proprio container; per un database esterno lanciare il comando `docker compose` equivalente senza `--profile`).

## Esposizione in produzione

`docker-compose.yml` non contiene più l'attacco a `web_network` né le label Traefik per `app`: sono specifiche del pattern di sviluppo (Traefik condiviso in locale, dominio `.localhost`) e vivono solo in `docker-compose.dev.yml`. `docker-compose.prod.yml` non pubblica nessuna porta né configura un reverse proxy al posto loro: la modalità di esposizione dipende dall'infrastruttura reale del deploy, che lo skeleton non può indovinare. Due opzioni tipiche, da aggiungere direttamente a `docker-compose.prod.yml`:

1.  **Pubblicare la porta direttamente** (`ports: ["80:80"]`), se il container è l'unico servizio sulla macchina — la terminazione TLS va gestita a parte (es. un proxy dedicato davanti).
2.  **Agganciarsi al proprio reverse proxy/Traefik di produzione**, se il server ospita più progetti o serve TLS via Let's Encrypt: stessa meccanica di `docker-compose.dev.yml` (`networks` + `labels`), ma con la rete e il dominio reali al posto di `web_network`/`*.localhost`.

## Accesso al database in produzione

Questa sezione vale solo per il database interno (profilo `internal-db`); con un database esterno l'accesso dipende dal provider. In produzione non è presente phpMyAdmin e il servizio `db` non pubblica alcuna porta sull'host: è raggiungibile solo dalla rete Docker interna. Per un accesso occasionale con un client grafico (es. MySQL Workbench):

1.  Trova l'IP interno del container: `docker inspect skeletron_apache_db | grep IPAddress`
2.  Apri un tunnel SSH verso il server puntato a quell'IP: `ssh -L 3306:<ip_interno_db>:3306 utente@server`
3.  Collega il client a `localhost:3306`

Nessuna porta resta in ascolto sull'host: il traffico passa cifrato via SSH. L'IP interno può cambiare se il container viene ricreato, quindi va riverificato all'occorrenza.

## Configurazione SMTP

Le variabili `MAIL_*` in `.env` configurano il client SMTP dell'applicativo (es. PHPMailer):

| Parametro    | Valore di default (sviluppo, `.env.example`) |
|--------------|------------------------------------------------|
| Host         | `mailpit` |
| Porta        | `1025`    |
| Cifratura    | `none`    |
| Utente       | *(vuoto, Mailpit non richiede autenticazione)* |
| Password     | *(vuoto)* |
| From address | `noreply@skeletron-apache.localhost` (sostituito da `setup.sh` col dominio `.localhost` del nuovo progetto) |
| From name    | `SkeletronApache` (sostituito da `setup.sh` col nome del progetto in PascalCase) |

In produzione basta sostituire questi valori con quelli del provider SMTP reale nel file `.env`: il codice applicativo resta invariato. Note d'integrazione lato PHPMailer:
- `SMTPAuth` va derivato (`true` se `MAIL_USERNAME`/`MAIL_PASSWORD` sono entrambe valorizzate, altrimenti `false`), non serve una variabile a parte
- `MAIL_ENCRYPTION=none` va tradotto in stringa vuota per `SMTPSecure` (PHPMailer non accetta il valore letterale `"none"`)

## Backup del database (opzionale)

`docker-compose.backup.yml` aggiunge un servizio `backup` che esegue dump periodici di MariaDB; è un layer a parte, va incluso esplicitamente (`make start-backup`) e non parte con `start-dev`/`start-prod`.

Funzionamento: un container basato su Alpine + `mariadb-client` esegue `mariadb-dump` secondo lo schedule configurato (cron interno), comprime il risultato e lo scrive in `./backups` sull'host (bind mount, quindi sopravvive alla ricreazione del container); i dump più vecchi della retention configurata vengono eliminati automaticamente.

| Variabile               | Default (`.env.example`) | Significato |
|--------------------------|---------------------------|-------------|
| `BACKUP_SCHEDULE`        | `0 3 * * *`               | espressione cron (qui: ogni notte alle 3) |
| `BACKUP_RETENTION_DAYS`  | `7`                        | giorni oltre i quali i dump vengono cancellati |

La cartella `./backups` è esclusa da Git (`.gitignore`): i dump non vanno versionati. Per una protezione reale contro un guasto del server, vanno copiati periodicamente altrove (storage esterno/offsite) — questo layer copre solo la generazione locale dei dump, non la loro replica remota.

## Sisma CLI

Il comando `sisma` è disponibile come eseguibile all'interno del container `skeletron_apache_app`:

```bash
docker exec -it skeletron_apache_app sisma install NomeProgetto
```

## Utilizzo come base per un nuovo progetto

### Metodo automatico (consigliato)

Esegui lo script interattivo dalla root del progetto:

```bash
bash setup.sh
```

Lo script chiederà il nome del progetto (in snake\_case o kebab-case) e le credenziali del database, aggiornerà tutti i file di configurazione, avvierà lo stack di sviluppo (`docker-compose.yml` + `docker-compose.dev.yml`) e lancerà `sisma install` automaticamente.

### Metodo manuale

1.  Scarica la release desiderata
2.  Rinomina `skeletron_apache.sql` con il nome del tuo progetto e aggiorna i riferimenti in `docker-compose.yml`, `docker-compose.dev.yml` **e `docker-compose.backup.yml`**
3.  Copia `.env.example` in `.env` e aggiorna le credenziali del database (e la passphrase di cifratura) lì, oltre che nel file `.sql` rinominato
4.  Esegui `make start-dev` (equivalente a `docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile internal-db up -d`)
5.  Avvia l'installazione con il comando `sisma install` (le credenziali nel container sono già configurate tramite `.env`: l'installer salta automaticamente la richiesta interattiva)

Per l'avvio in produzione, usare invece `make start-prod` (senza phpMyAdmin e Mailpit, con database interno) o `make start-prod-external-db` (database gestito esternamente, vedi "Database interno o esterno"), oppure `make start-backup` per includere anche il backup schedulato del database interno.
