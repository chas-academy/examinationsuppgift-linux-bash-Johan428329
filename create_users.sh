#!/bin/bash

# kontrollera att vi kör som root
if [[ $EUID -ne 0 ]]; then
    echo "Du måste vara root för att köra det här scriptet"
    exit 1
fi

# kolla att vi har argument
if [[ $# -eq 0 ]]; then
    echo "Användning: $0 user1 [user2 user3 ...]"
    exit 1
fi

# räkna skapade användare
users_created=0

# loopa genom användarnamnen
for username in "$@"; do
    # skapa användaren om den inte finns
    if ! id "$username" &>/dev/null; then
        useradd -m "$username"
        if [ $? -eq 0 ]; then
            ((users_created++))
        fi
    else
        # redan befintlig användare
        ((users_created++))
    fi
    
    # hämta hemkatalog
    homedir=$(getent passwd "$username" | cut -d: -f6)
    
    # hoppa över om hemkatalog inte finns
    if [ -z "$homedir" ]; then
        continue
    fi
    
    # skapa mapparna
    mkdir -p "$homedir/Documents"
    mkdir -p "$homedir/Downloads"
    mkdir -p "$homedir/Work"
    
    # sätt rättigheter (700 = bara ägaren)
    chmod 700 "$homedir/Documents"
    chmod 700 "$homedir/Downloads"
    chmod 700 "$homedir/Work"
    
    # användar äger sina mappar
    chown "$username:$username" "$homedir/Documents"
    chown "$username:$username" "$homedir/Downloads"
    chown "$username:$username" "$homedir/Work"
    
    # hämta alla systemanvändare
    users=$(cut -d: -f1 /etc/passwd | grep -v "^$" | sort)
    
    # skapa välkomstfilen
    wfile="$homedir/welcome.txt"
    echo "Välkommen $username" > "$wfile"
    echo "" >> "$wfile"
    echo "alla användare i systemet:" >> "$wfile"
    echo "$users" >> "$wfile"
    
    # rättigheter på welcome-filen
    chmod 600 "$wfile"
    chown "$username:$username" "$wfile"
done

# avslut med rätt kod
if [ $users_created -gt 0 ]; then
    exit 0
else
    exit 1
fi
