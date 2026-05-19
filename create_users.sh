#!/bin/bash

# måste köra som root
if [[ $EUID -ne 0 ]]; then
    echo "Du måste vara root för att köra det här scriptet"
    exit 1
fi

# kollar att vi har användare som input
if [[ $# -eq 0 ]]; then
    echo "Användning: $0 user1 [user2 user3 ...]"
    exit 1
fi

# loopar igenom alla användarnamn som skickades
for username in "$@"; do
    # skapar användaren
    if ! id "$username" &>/dev/null; then
        useradd "$username" 2>/dev/null
    fi
    
    # får reda på hemkatalogen
    homedir=$(getent passwd "$username" | cut -d: -f6)
    
    # skapar mapparna som krävs
    mkdir -p "$homedir/Documents"
    mkdir -p "$homedir/Downloads" 
    mkdir -p "$homedir/Work"
    
    # sätt rätt rättigheter på mapparna
    chmod 700 "$homedir/Documents"
    chmod 700 "$homedir/Downloads"
    chmod 700 "$homedir/Work"
    
    # användaren ska äga sina egna mappar
    chown "$username:$username" "$homedir/Documents"
    chown "$username:$username" "$homedir/Downloads"
    chown "$username:$username" "$homedir/Work"
    
    # hämta alla användare från systemet
    users=$(cut -d: -f1 /etc/passwd | grep -v "^$" | sort)
    
    # skapar välkomstfilen
    wfile="$homedir/welcome.txt"
    echo "Välkommen $username" > "$wfile"
    echo "" >> "$wfile"
    echo "alla användare i systemet:" >> "$wfile"
    echo "$users" >> "$wfile"
    
    # sätt rätt ägare och rättigheter på welcome filen
    chmod 600 "$wfile"
    chown "$username:$username" "$wfile"
done
