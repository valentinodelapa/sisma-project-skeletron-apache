#!/usr/bin/env bash
# Setup iniziale per sisma-project-skeletron-apache
# Uso: bash setup.sh  (dalla root del progetto)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VARIANT="apache"
OLD_SNAKE="skeletron_apache"
OLD_KEBAB="skeletron-apache"
OLD_PASCAL=""  # calcolato più sotto, dopo la definizione di to_pascal

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

OLD_PASCAL="$(to_pascal "$OLD_KEBAB")"

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

# ─── 1b. Sottomoduli aggiuntivi ───────────────────────────────────────────────
SUBMODULES=()  # coppie "url|www/cartella"

echo ""
read -rp "Aggiungere ulteriori sottomoduli Git in www/? [s/N]: " _add_subs
if [[ "$_add_subs" =~ ^[sS]$ ]]; then
    echo ""
    info "I sottomoduli verranno clonati in www/<nome-cartella>"
    info "Lascia l'URL vuoto per terminare."
    echo ""
    while true; do
        read -rp "  URL repository (o Invio per terminare): " _sub_url
        _sub_url=$(echo "$_sub_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$_sub_url" ] && break
        if ! echo "$_sub_url" | grep -qE '^(https?://|ssh://|git://|[A-Za-z0-9._-]+@).+'; then
            warn "URL non valido. Usa https://..., ssh://..., git://... o utente@host:percorso"; continue
        fi
        while true; do
            read -rp "  Nome cartella in www/: " _sub_folder
            _sub_folder=$(echo "$_sub_folder" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -z "$_sub_folder" ]; then
                warn "Il nome della cartella non può essere vuoto."; continue
            fi
            if ! echo "$_sub_folder" | grep -qE '^[a-zA-Z][a-zA-Z0-9_-]*$'; then
                warn "Usa solo lettere, cifre, trattini e underscore."; continue
            fi
            _dup=0
            for _s in "${SUBMODULES[@]}"; do
                [[ "${_s##*|}" == "www/$_sub_folder" ]] && _dup=1 && break
            done
            [ "$_dup" -eq 1 ] && { warn "Cartella 'www/$_sub_folder' già aggiunta."; continue; }
            break
        done
        SUBMODULES+=("${_sub_url}|www/${_sub_folder}")
        ok "  → www/$_sub_folder"
        echo ""
    done
fi

# ─── 1c. Repository aggiuntivi come subtree ───────────────────────────────────
SUBTREES=()  # tuple "url|www/cartella|branch|squash_flag"

echo ""
read -rp "Aggiungere ulteriori repository come subtree in www/? [s/N]: " _add_subtrees
if [[ "$_add_subtrees" =~ ^[sS]$ ]]; then
    echo ""
    info "I subtree verranno aggiunti in www/<nome-cartella>"
    info "Lascia l'URL vuoto per terminare."
    echo ""
    while true; do
        read -rp "  URL repository (o Invio per terminare): " _sub_url
        _sub_url=$(echo "$_sub_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$_sub_url" ] && break
        if ! echo "$_sub_url" | grep -qE '^(https?://|ssh://|git://|[A-Za-z0-9._-]+@).+'; then
            warn "URL non valido. Usa https://..., ssh://..., git://... o utente@host:percorso"; continue
        fi
        while true; do
            read -rp "  Nome cartella in www/: " _sub_folder
            _sub_folder=$(echo "$_sub_folder" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -z "$_sub_folder" ]; then
                warn "Il nome della cartella non può essere vuoto."; continue
            fi
            if ! echo "$_sub_folder" | grep -qE '^[a-zA-Z][a-zA-Z0-9_-]*$'; then
                warn "Usa solo lettere, cifre, trattini e underscore."; continue
            fi
            _dup=0
            for _s in "${SUBMODULES[@]}"; do
                [[ "${_s##*|}" == "www/$_sub_folder" ]] && _dup=1 && break
            done
            for _s in "${SUBTREES[@]}"; do
                IFS='|' read -r _ _s_path _ _ <<< "$_s"
                [[ "$_s_path" == "www/$_sub_folder" ]] && _dup=1 && break
            done
            [ "$_dup" -eq 1 ] && { warn "Cartella 'www/$_sub_folder' già aggiunta."; continue; }
            break
        done
        read -rp "  Branch [main]: " _sub_branch
        _sub_branch=$(echo "$_sub_branch" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        _sub_branch="${_sub_branch:-main}"
        read -rp "  Usare --squash (storia compressa in un unico commit)? [S/n]: " _sub_squash
        if [[ "$_sub_squash" =~ ^[nN]$ ]]; then
            _sub_squash_flag=""
        else
            _sub_squash_flag="--squash"
        fi
        SUBTREES+=("${_sub_url}|www/${_sub_folder}|${_sub_branch}|${_sub_squash_flag}")
        ok "  → www/$_sub_folder (branch: $_sub_branch)"
        echo ""
    done
fi

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
if [ ${#SUBMODULES[@]} -gt 0 ]; then
    printf "  Sottomoduli :\n"
    for _s in "${SUBMODULES[@]}"; do
        printf "    %s\n" "${_s##*|}"
    done
fi
if [ ${#SUBTREES[@]} -gt 0 ]; then
    printf "  Subtree     :\n"
    for _s in "${SUBTREES[@]}"; do
        IFS='|' read -r _ _s_path _s_branch _ <<< "$_s"
        printf "    %s (branch: %s)\n" "$_s_path" "$_s_branch"
    done
fi
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

# ─── 5. Aggiorna i docker-compose*.yml ────────────────────────────────────────
# Le credenziali non vengono più scritte qui: docker-compose.yml legge da .env
# tramite ${...} ed env_file, quindi restano identiche per ogni progetto.
rif "docker-compose.yml" "$OLD_SNAKE" "$NEW_SNAKE"
ok "docker-compose.yml aggiornato"

rif "docker-compose.dev.yml" "$OLD_SNAKE" "$NEW_SNAKE"
rif "docker-compose.dev.yml" "$OLD_KEBAB" "$NEW_KEBAB"
ok "docker-compose.dev.yml aggiornato"

rif "docker-compose.backup.yml" "$OLD_SNAKE" "$NEW_SNAKE"
rif "docker-compose.backup.yml" "$OLD_KEBAB" "$NEW_KEBAB"
ok "docker-compose.backup.yml aggiornato"

# ─── 5b. Genera il file .env ──────────────────────────────────────────────────
# Generata qui (non richiesta all'utente) e scritta solo in .env, mai in un file
# committato: SismaFramework la legge via getenv() in Config/configFramework.php.
# La lunghezza della chiave dipende dall'algoritmo configurato in
# Config/config.php (ENCRYPTION_ALGORITHM), letto da lì e non fissato qui:
# Encryptor::encryptString/decryptString passa ENCRYPTION_PASSPHRASE a
# openssl_encrypt/decrypt senza derivazione, quindi deve avere esattamente la
# lunghezza attesa dal cifrario (es. AES-256-* → 32 byte, AES-128-* → 16 byte).
CONFIG_FILE="www/SismaFramework/Config/config.php"
[ -f "$CONFIG_FILE" ] || die "File di configurazione non trovato: $CONFIG_FILE"

ENCRYPTION_ALGORITHM="$(sed -nE "s/^const ENCRYPTION_ALGORITHM = [\"']([^\"']+)[\"'];.*/\1/p" "$CONFIG_FILE")"
[ -n "$ENCRYPTION_ALGORITHM" ] || die "Impossibile determinare ENCRYPTION_ALGORITHM da $CONFIG_FILE"

KEY_BITS="$(echo "$ENCRYPTION_ALGORITHM" | grep -oE '[0-9]+' | head -n1)"
case "$KEY_BITS" in
    128|192|256) ;;
    *) die "Lunghezza chiave non riconosciuta per l'algoritmo '$ENCRYPTION_ALGORITHM' (atteso un cifrario AES-<128|192|256>-<modalità>)." ;;
esac
KEY_BYTES=$((KEY_BITS / 8))

ENCRYPTION_PASSPHRASE="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$KEY_BYTES" || true)"
info "Chiave di cifratura generata per $ENCRYPTION_ALGORITHM (${KEY_BYTES} byte)"

cp .env.example .env
rif ".env" "DB_ROOT_PASSWORD=change_me_root_password"             "DB_ROOT_PASSWORD=${ROOT_PASS}"
rif ".env" "DATABASE_NAME=${OLD_SNAKE}"                            "DATABASE_NAME=${NEW_SNAKE}"
rif ".env" "DATABASE_USERNAME=db_user"                             "DATABASE_USERNAME=${DB_USER}"
rif ".env" "DATABASE_PASSWORD=change_me_db_password"               "DATABASE_PASSWORD=${DB_PASS}"
rif ".env" "ENCRYPTION_PASSPHRASE=change_me_encryption_passphrase" "ENCRYPTION_PASSPHRASE=${ENCRYPTION_PASSPHRASE}"
rif ".env" "MAIL_FROM_ADDRESS=noreply@${OLD_KEBAB}.localhost"      "MAIL_FROM_ADDRESS=noreply@${NEW_KEBAB}.localhost"
rif ".env" "MAIL_FROM_NAME=${OLD_PASCAL}"                          "MAIL_FROM_NAME=${PROJECT_PASCAL}"
ok ".env generato (non versionato)"

# ─── 6. Sottomoduli Git ──────────────────────────────────────────────────────
if [ ${#SUBMODULES[@]} -gt 0 ]; then
    echo ""
    info "Aggiungo sottomoduli Git..."
    for _s in "${SUBMODULES[@]}"; do
        _sub_url="${_s%%|*}"
        _sub_path="${_s##*|}"
        git submodule add "$_sub_url" "$_sub_path"
        ok "Sottomodulo aggiunto: $_sub_path"
    done
    git submodule update --init --recursive
    ok "Sottomoduli inizializzati"
fi

# ─── 6b. Repository aggiuntivi come subtree ───────────────────────────────────
# git subtree add richiede un working tree pulito (nessuna modifica non
# committata in file tracciati o in index): a questo punto docker-compose*.yml
# sono già stati riscritti e gli eventuali sottomoduli sono già in index, quindi
# mettiamo tutto da parte con git stash e lo ripristiniamo subito dopo.
# NB: git stash NON mette da parte un sottomodulo il cui commit differisce da
# quello registrato nell'indice ("modified: www/... (new commits)"): in tal caso
# risponde "No local changes to save" senza fare nulla, e la successiva
# ensure_clean di git-subtree (che confronta con git diff-index HEAD, senza
# --ignore-submodules) fallirebbe comunque. Riallineiamo prima i sottomoduli
# al commit registrato, così lo stash copre solo le modifiche "vere".
# NB2: git stash non può in ogni caso mettere da parte modifiche INTERNE al
# working tree di un sottomodulo (file modificati o non tracciati al suo
# interno: è un repository separato). Su Windows, con core.autocrlf=true, un
# sottomodulo appena clonato risulta spesso "sporco" subito dopo il checkout
# per via della rinormalizzazione dei fine-riga, e ciò basta a far fallire
# ensure_clean anche a stash riuscito. Riportiamo quindi ogni sottomodulo a
# uno stato realmente pristino (reset + clean) prima dello stash: qui non c'è
# lavoro dell'utente da preservare, sono appena stati clonati o sono quelli
# già pinnati del framework.
if [ ${#SUBTREES[@]} -gt 0 ]; then
    echo ""
    git submodule update --recursive
    git submodule foreach --recursive 'git reset --hard && git clean -fd'
    _stash_output=$(git stash push -m "setup.sh: modifiche pre-subtree" 2>&1) || die "Impossibile mettere da parte le modifiche pendenti (git stash): $_stash_output"
    if [[ "$_stash_output" == *"No local changes to save"* ]]; then
        _stash_created=0
    else
        _stash_created=1
        ok "Modifiche pendenti messe temporaneamente da parte (git stash)"
    fi

    info "Aggiungo repository come subtree..."
    for _s in "${SUBTREES[@]}"; do
        IFS='|' read -r _sub_url _sub_path _sub_branch _sub_squash_flag <<< "$_s"
        git subtree add --prefix="$_sub_path" "$_sub_url" "$_sub_branch" $_sub_squash_flag
        ok "Subtree aggiunto: $_sub_path"
    done

    if [ "$_stash_created" -eq 1 ]; then
        git stash pop
        ok "Modifiche pendenti ripristinate"
    fi
fi

# ─── 7. Avvia Docker ──────────────────────────────────────────────────────────
echo ""
docker info > /dev/null 2>&1 || die "Docker non è in esecuzione. Avvia Docker Desktop e riprova."
info "Avvio dei container Docker (stack di sviluppo)..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile internal-db up -d
ok "Container avviati"

# ─── 8. Attendi che il DB sia pronto ─────────────────────────────────────────
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

# ─── 9. Esegui sisma install ──────────────────────────────────────────────────
APP_CONTAINER="${NEW_SNAKE}_app"

echo ""
read -rp "Eseguire 'sisma install' con l'opzione --module? [s/N]: " _use_module
MODULE_FLAG=""
if [[ "$_use_module" =~ ^[sS]$ ]]; then
    while true; do
        read -rp "  Nome modulo: " _module_name
        _module_name=$(echo "$_module_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$_module_name" ] && { warn "Il nome del modulo non può essere vuoto."; continue; }
        break
    done
    MODULE_FLAG="--module=${_module_name}"
fi

echo ""
info "Avvio installazione nel container $APP_CONTAINER..."
info "Le credenziali del database sono già disponibili come variabili d'ambiente"
info "(da .env via env_file): l'installer le rileva e salta la richiesta interattiva."
echo ""

# Git Bash / MSYS2 su Windows non supporta l'allocazione TTY via Docker
[ -n "${MSYSTEM:-}" ] && TTY_FLAG="-i" || TTY_FLAG="-it"
docker exec $TTY_FLAG "$APP_CONTAINER" sisma install "$PROJECT_PASCAL" $MODULE_FLAG

# ─── 10. Composer install ─────────────────────────────────────────────────────
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
printf "  Mailpit      : http://mail.%s.localhost\n" "$NEW_KEBAB"
echo ""
warn "Credenziali e chiave di cifratura salvate in .env (non versionato). Conservane una copia."
echo ""

rm -- "${BASH_SOURCE[0]}"
git add .
git commit -m "Initial commit"
