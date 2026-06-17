#!/usr/bin/env bash
# Setup iniziale per sisma-project-skeletron-apache
# Uso: bash setup.sh  (dalla root del progetto)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VARIANT="apache"
OLD_SNAKE="skeletron_apache"
OLD_KEBAB="skeletron-apache"

# ─── Colori ──────────────────────────────────────────────────────────────────
B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
info() { echo -e "${B}▸${NC} $*"; }
ok()   { echo -e "${G}✓${NC} $*"; }
warn() { echo -e "${Y}!${NC} $*"; }
die()  { echo -e "${R}✗ $*${NC}" >&2; exit 1; }

# ─── Sostituzione portabile (Linux e macOS) ───────────────────────────────────
rif() {   # rif <file> <da_cercare> <sostituto>
    local tmp; tmp=$(mktemp)
    sed "s|${2}|${3}|g" "$1" > "$tmp" && mv "$tmp" "$1"
}

# ─── snake_case / kebab-case → PascalCase ─────────────────────────────────────
to_pascal() {
    echo "$1" | awk -F'[-_]' \
        '{for(i=1;i<=NF;i++) printf toupper(substr($i,1,1)) substr($i,2); print ""}'
}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Sisma Skeleton Setup — Apache          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ─── 1. Nome del progetto ─────────────────────────────────────────────────────
while true; do
    read -rp "Nome progetto (snake_case o kebab-case, es: my-project): " _raw
    _raw=$(echo "$_raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$_raw" ]; then
        warn "Il nome non può essere vuoto."; continue
    fi
    if ! echo "$_raw" | grep -qE '^[a-z][a-z0-9_-]*$'; then
        warn "Usa solo lettere minuscole, cifre, trattini (-) e underscore (_). Deve iniziare con una lettera."
        continue
    fi
    break
done

PROJECT_SNAKE=$(echo "$_raw" | tr '-' '_')
PROJECT_KEBAB=$(echo "$_raw" | tr '_' '-')
PROJECT_PASCAL=$(to_pascal "$PROJECT_KEBAB")

NEW_SNAKE="$PROJECT_SNAKE"
NEW_KEBAB="$PROJECT_KEBAB"

echo ""
info "Nomi che verranno usati:"
printf "    snake_case : %s\n"  "$NEW_SNAKE"
printf "    kebab-case : %s\n"  "$NEW_KEBAB"
printf "    PascalCase : %s\n"  "$PROJECT_PASCAL"

# ─── 2. Credenziali database ──────────────────────────────────────────────────
echo ""
echo "Credenziali database:"
echo ""
read -rsp "  Password root         [root_password]: " ROOT_PASS
echo ""
ROOT_PASS="${ROOT_PASS:-root_password}"

read -rp  "  Username utente guest [db_user]:       " DB_USER
DB_USER="${DB_USER:-db_user}"

read -rsp "  Password utente guest [db_password]:   " DB_PASS
echo ""
DB_PASS="${DB_PASS:-db_password}"

# ─── 3. Riepilogo e conferma ──────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────────────"
printf "  DB / slug   : %s\n"      "$NEW_SNAKE"
printf "  App URL     : http://%s.localhost\n"    "$NEW_KEBAB"
printf "  phpMyAdmin  : http://db.%s.localhost\n" "$NEW_KEBAB"
printf "  DB root     : %s\n"      "[nascosta]"
printf "  DB user     : %s\n"      "$DB_USER"
printf "  DB password : %s\n"      "[nascosta]"
echo "──────────────────────────────────────────────────"
echo ""
read -rp "Procedere con il setup? [s/N]: " _confirm
[[ "$_confirm" =~ ^[sS]$ ]] || { info "Operazione annullata."; exit 0; }

# ─── 4. Rinomina e aggiorna il file SQL ───────────────────────────────────────
OLD_SQL="${OLD_SNAKE}.sql"
NEW_SQL="${NEW_SNAKE}.sql"

[ -f "$OLD_SQL" ] || die "File SQL non trovato: $OLD_SQL"

cp "$OLD_SQL" "$NEW_SQL"
rif "$NEW_SQL" "$OLD_SNAKE"  "$NEW_SNAKE"
rif "$NEW_SQL" "'db_user'"   "'${DB_USER}'"
ok "$OLD_SQL → $NEW_SQL (aggiornato)"

# ─── 5. Aggiorna docker-compose.yml ──────────────────────────────────────────
rif "docker-compose.yml" "$OLD_SNAKE"                           "$NEW_SNAKE"
rif "docker-compose.yml" "$OLD_KEBAB"                           "$NEW_KEBAB"
rif "docker-compose.yml" "MARIADB_ROOT_PASSWORD: root_password" "MARIADB_ROOT_PASSWORD: ${ROOT_PASS}"
rif "docker-compose.yml" "MYSQL_ROOT_PASSWORD: root_password"   "MYSQL_ROOT_PASSWORD: ${ROOT_PASS}"
rif "docker-compose.yml" "MARIADB_USER: db_user"                "MARIADB_USER: ${DB_USER}"
rif "docker-compose.yml" "MARIADB_PASSWORD: db_password"        "MARIADB_PASSWORD: ${DB_PASS}"
ok "docker-compose.yml aggiornato"

# ─── 6. Avvia Docker ──────────────────────────────────────────────────────────
echo ""
docker info > /dev/null 2>&1 || die "Docker non è in esecuzione. Avvia Docker Desktop e riprova."
info "Avvio dei container Docker..."
docker compose up -d
ok "Container avviati"

# ─── 7. Attendi che il DB sia pronto ─────────────────────────────────────────
DB_CONTAINER="${NEW_SNAKE}_db"
echo ""
info "Attendo che il database sia pronto ($DB_CONTAINER)..."

MAX_WAIT=90
ELAPSED=0
until docker exec "$DB_CONTAINER" mariadb -u root -p"$ROOT_PASS" -e "SELECT 1" > /dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo ""
        die "Il database non è diventato disponibile entro ${MAX_WAIT}s.
    Prova manualmente: docker exec -it ${DB_CONTAINER} mariadb -u root -p"
    fi
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    printf '.'
done
echo ""
ok "Database pronto"

# ─── 8. Esegui sisma install ──────────────────────────────────────────────────
APP_CONTAINER="${NEW_SNAKE}_app"

echo ""
info "Avvio installazione nel container $APP_CONTAINER..."
echo ""
warn "Se l'installer chiede le credenziali del database, usa questi valori:"
printf "    Host     : %s\n"  "${NEW_SNAKE}_db"
printf "    Database : %s\n"  "$NEW_SNAKE"
printf "    User     : %s\n"  "$DB_USER"
printf "    Password : %s\n"  "$DB_PASS"
echo ""

# Git Bash / MSYS2 su Windows non supporta l'allocazione TTY via Docker
[ -n "${MSYSTEM:-}" ] && TTY_FLAG="-i" || TTY_FLAG="-it"
docker exec $TTY_FLAG "$APP_CONTAINER" sisma install "$PROJECT_PASCAL"

# ─── 9. Composer install ──────────────────────────────────────────────────────
echo ""
info "Eseguo composer install in /var/www/html/ ..."
docker exec "$APP_CONTAINER" bash -c "cd /var/www/html && composer install"
ok "Dipendenze Composer installate"

# ─── Fine ─────────────────────────────────────────────────────────────────────
echo ""
ok "Setup completato!"
echo ""
printf "  Applicazione : http://%s.localhost\n"    "$NEW_KEBAB"
printf "  phpMyAdmin   : http://db.%s.localhost\n" "$NEW_KEBAB"
echo ""

rm -- "${BASH_SOURCE[0]}"
git add .
git commit -m "Initial commit"
