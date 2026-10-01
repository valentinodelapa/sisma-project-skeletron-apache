ALTER DATABASE skeletron_apache CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- root: tutti i permessi (già garantiti di default)
GRANT ALL PRIVILEGES ON skeletron_apache.* TO 'root'@'%';

-- db_user: solo operazioni DML
-- L'entrypoint dell'immagine MariaDB (MARIADB_USER + MARIADB_DATABASE) assegna
-- all'utente GRANT ALL sullo schema prima di eseguire questo file, registrato
-- col nome dello schema escapato (`_` → `\_`): una REVOKE ... ON <schema>.*
-- non lo troverebbe. Si revoca quindi tutto a ogni livello e si riassegna il DML.
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'db_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON skeletron_apache.* TO 'db_user'@'%';

FLUSH PRIVILEGES;
