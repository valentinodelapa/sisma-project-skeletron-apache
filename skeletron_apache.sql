ALTER DATABASE skeletron_apache CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- root: tutti i permessi (già garantiti di default)
GRANT ALL PRIVILEGES ON skeletron_apache.* TO 'root'@'%';

-- db_user: solo operazioni DML
GRANT SELECT, INSERT, UPDATE, DELETE ON skeletron_apache.* TO 'db_user'@'%';

FLUSH PRIVILEGES;
