#!/bin/bash

# kontroller root
if [[ $EUID -ne 0 ]]; then
    echo "Fel: scriptet måste köras som root"
    exit 1
fi

# minst en användare som argument
if [[ $# -eq 0 ]]; then
    echo "Användning: $0 användarnamn1 [användarnamn2 ...]"
    exit 1
fi

folders=("Documents" "Downloads" "Work")

# loop som skapar alla användare och sätter upp katalogstruktur

for username in "$@"; do
	# ifall anvädare med hemkatalog inte finns, så skapades det
    if ! id "$username" &>/dev/null; then
        useradd -m "$username"
    fi

	# skapa undermappar i hemkatalog
    for folder in "${folders[@]}"; do
        mkdir -p "/home/$username/$folder"
    done

    # korrekt behörighet till mappen
    chown -R "$username:$username" "/home/$username"

    # sätta rättigheter ill ägaren (700)
    chmod 700 "/home/$username"
    chmod 700 "/home/$username/Documents"
    chmod 700 "/home/$username/Downloads"
    chmod 700 "/home/$username/Work"
done

# andra loopen som skapad welcome.txt, då alla användare finns i system.
for username in "$@"; do
    wfile="/home/$username/welcome.txt"

	# personalizerad meddelande för välkomst
    echo "Välkommen $username" > "$wfile"
    echo "" >> "$wfile"
    echo "alla användare i systemet:" >> "$wfile"

    # lista alla användare i systemet
    cut -d: -f1 /etc/passwd | sort >> "$wfile"

    # rättigheter så att endast ägaren ska kunna läsa
    chown "$username:$username" "$wfile"
    chmod 600 "$wfile"
done