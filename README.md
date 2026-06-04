# SismaSkeletronApache

[![PHP Version Support](https://img.shields.io/badge/php-%3E%3D8.5-blue)](https://www.php.net/)
[![license](https://img.shields.io/badge/license-MIT-yellowgreen)](https://github.com/valentinodelapa/sisma-project-skeletron-apache/blob/master/LICENSE)
[![SLSA 3](https://img.shields.io/badge/SLSA-Level%203-blue)](https://slsa.dev/spec/v0.1/levels#level-3)

Skeleton Docker per progetti basati su SismaFramework con server web Apache.

## Stack

*   **PHP 8.5** con modulo Apache (`php:8.5-apache`)
*   **MariaDB** (ultima versione)
*   **phpMyAdmin** per la gestione del database
*   **Traefik** come reverse proxy per lo sviluppo locale

## Prerequisiti

*   Docker e Docker Compose
*   Traefik in esecuzione sulla rete esterna `web_network`

## Avvio

```bash
docker compose up -d
```

L'applicazione sarà disponibile su `http://skeletron-apache.localhost` e phpMyAdmin su `http://db.skeletron-apache.localhost`.

## Credenziali database

| Parametro       | Valore             |
|-----------------|--------------------|
| Host            | `skeletron_apache_db` |
| Database        | `skeletron_apache` |
| Utente          | `db_user`          |
| Password        | `db_password`      |
| Password root   | `root_password`    |

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

Lo script chiederà il nome del progetto (in snake\_case o kebab-case) e le credenziali del database, aggiornerà tutti i file di configurazione, avvierà i container e lancerà `sisma install` automaticamente.

### Metodo manuale

1.  Scarica la release desiderata
2.  Rinomina `skeletron_apache.sql` con il nome del tuo progetto e aggiorna i riferimenti in `docker-compose.yml`
3.  Aggiorna le credenziali del database in `docker-compose.yml` e nel file `.sql` rinominato
4.  Esegui `docker compose up -d`
5.  Avvia l'installazione con il comando `sisma install`
