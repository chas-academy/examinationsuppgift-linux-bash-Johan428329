#!/bin/bash

# maste vara root
if [[ $EUID -ne 0 ]]; then
    echo "Detta script maste koras som root (sudo)." >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "Anvandning: $0 <anvandarnamn1> [anvandarnamn2] ..." >&2
    exit 1
fi

# skapa anvandarna först
for user in "$@"; do
    if ! id "$user" &>/dev/null; then
        useradd -m "$user"
    fi
done

ALL_USERS=$(getent passwd | cut -d: -f1)

# sen konfigurera hemkatalogerna
for user in "$@"; do
    HOME_DIR=$(eval echo "~$user")

    mkdir -p "$HOME_DIR/Documents" "$HOME_DIR/Downloads" "$HOME_DIR/Work"

    chown "$user":"$user" "$HOME_DIR/Documents" "$HOME_DIR/Downloads" "$HOME_DIR/Work"
    chmod 700 "$HOME_DIR/Documents" "$HOME_DIR/Downloads" "$HOME_DIR/Work"

    # valkomstfil
    echo "Välkommen $user" > "$HOME_DIR/welcome.txt"
    echo "$ALL_USERS" >> "$HOME_DIR/welcome.txt"

    chown "$user":"$user" "$HOME_DIR/welcome.txt"
    chmod 600 "$HOME_DIR/welcome.txt"
done
