#!/bin/bash

# --- KONFIGURATION ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT="./create_users.sh"
TEST_USER="testelev"
TEST_USER_2="testkompis"
HOME_DIR="/home/$TEST_USER"

# --- HJÄLPFUNKTIONER ---
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

cleanup() {
    userdel -r $TEST_USER &>/dev/null
    userdel -r $TEST_USER_2 &>/dev/null
    
    # Zombie moment
    if [ ! -z "$TEST_USER" ]; then rm -rf "/home/$TEST_USER"; fi
    if [ ! -z "$TEST_USER_2" ]; then rm -rf "/home/$TEST_USER_2"; fi
}

ensure_setup() {
    if ! id "$TEST_USER" &>/dev/null; then
        ./$SCRIPT $TEST_USER $TEST_USER_2 &>/dev/null
    fi
}

# --- TESTFALL ---

# Test 1: Grundstruktur
test_shebang() {
    if [ ! -f "$SCRIPT" ]; then fail "Filen $SCRIPT saknas helt."; fi

    if ! head -n 1 "$SCRIPT" | grep -q "^#!/bin/bash"; then
        fail "Filen måste börja med #!/bin/bash"
    fi
    
    if ! grep -v "^#!/bin/bash" "$SCRIPT" | grep -q "#"; then
        fail "Saknar kommentarer (#) som förklarar koden."
    fi

    pass "Korrekt shebang och kommentarer hittades."
}

# Test 2: Root-check
test_root_check() {
    if [ ! -x "$SCRIPT" ]; then fail "Filen saknas eller är inte körbar (chmod +x)."; fi

    if sudo -u nobody "$SCRIPT" $TEST_USER &>/dev/null; then
        fail "Scriptet borde ha avbrutits (exit code != 0) när det kördes utan sudo."
    else
        pass "Scriptet stoppar korrekt icke-root användare."
    fi
}

# Test 3: Användarskapande
test_creation() {
    cleanup
    if ./$SCRIPT $TEST_USER $TEST_USER_2 > /dev/null; then
         if id "$TEST_USER" &>/dev/null && id "$TEST_USER_2" &>/dev/null; then
            pass "Användarna $TEST_USER och $TEST_USER_2 skapades."
         else
            fail "Scriptet kördes men användarna hittades inte i systemet."
         fi
    else
         fail "Scriptet kraschade (felkod) vid körning."
    fi
}

# Test 4: Katalogstruktur 
test_folders() {
    ensure_setup
    MISSING=0
    for dir in "Documents" "Downloads" "Work"; do
        if [ ! -d "$HOME_DIR/$dir" ]; then
            echo -e "${RED}Saknar mapp: $dir${NC}"
            MISSING=1
        fi
    done
    
    if [ $MISSING -eq 0 ]; then
        pass "Alla mappar (Documents, Downloads, Work) skapades."
    else
        fail "En eller flera mappar saknades."
    fi
}

# Test 5: Rättigheter 
test_permissions() {
    ensure_setup
    TARGET="$HOME_DIR/Work"
    if [ ! -d "$TARGET" ]; then fail "Kan inte testa rättigheter, mappen Work saknas."; fi

    OWNER=$(stat -c '%U' "$TARGET")
    if [ "$OWNER" != "$TEST_USER" ]; then
        fail "Fel ägare. Förväntat: $TEST_USER, Fick: $OWNER"
    fi

    PERM=$(stat -c "%a" "$TARGET")
    if [[ "$PERM" == "700" || "$PERM" == "750" || "$PERM" == "705" ]]; then
        pass "Rättigheterna är strikta ($PERM)."
    else
        fail "Osäkra rättigheter: $PERM (Borde vara t.ex. 700)."
    fi
}

# Test 6: Välkomstmeddelande
test_welcome() {
    ensure_setup
    FILE="$HOME_DIR/welcome.txt"
    
    # 1. Finns filen?
    if [ ! -f "$FILE" ]; then fail "Filen welcome.txt saknas."; fi

    # 2. KONTROLLERA RUBRIK (Case insensitive med -i)
    # Vi letar efter "Välkommen testelev"
    if ! grep -i "Välkommen $TEST_USER" "$FILE"; then
        echo "--------------------------------"
        cat "$FILE"
        echo "--------------------------------"
        fail "Filen saknar korrekt rubrik. Den ska börja med: 'Välkommen $TEST_USER'"
    fi

    # 3. KONTROLLERA DYNAMISK LISTA
    if grep -q "$TEST_USER_2" "$FILE"; then
        pass "Korrekt rubrik och användarlista hittades."
    else
        echo "--------------------------------"
        cat "$FILE"
        echo "--------------------------------"
        fail "Listan är ofullständig. Hittade inte den andra användaren ('$TEST_USER_2')."
    fi
}

# Test 7: Video 
test_video() {
    VIDEO_FILE="./videoprov.mp4"

    if [ ! -f "$VIDEO_FILE" ]; then 
        fail "Filen videoprov.mp4 saknas i roten."
    fi

    pass "Videoinlämning hittad."
}

# --- EXEKVERING ---

run_all() {
    echo -e "${YELLOW}🚀 Startar alla tester...${NC}"
    
    echo -n "Städar undan gamla testanvändare... "
    cleanup
    echo "Klar."

    echo "-----------------------------------"
    FAIL_COUNT=0
    
    (test_shebang) || ((FAIL_COUNT++))
    (test_root_check) || ((FAIL_COUNT++))
    (test_creation) || ((FAIL_COUNT++))
    (test_folders) || ((FAIL_COUNT++))
    (test_permissions) || ((FAIL_COUNT++))
    (test_welcome) || ((FAIL_COUNT++))
    (test_video) || ((FAIL_COUNT++))

    echo "-----------------------------------"
    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}✨ GRATTIS! Alla tester godkända! ✨${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  Totalt antal fel: $FAIL_COUNT${NC}"
        exit 1
    fi
}

if [ -z "$1" ] || [ "$1" == "all" ]; then
    run_all
else
    case "$1" in
        1) test_shebang ;;
        2) test_root_check ;;
        3) test_creation ;;
        4) test_folders ;;
        5) test_permissions ;;
        6) test_welcome ;;
        7) test_video ;;
        *) echo "Ogiltigt val: $1"; exit 1 ;;
    esac
fi
exit 0