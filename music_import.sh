#!/bin/bash

# Konfigurierbare Pfade und Zeit
M3U_FOLDER="/mnt/pve/media/music/downloads"
NEW_M3U_FOLDER="/mnt/pve/media/music/library/"
CONTAINER_NAME="beets"
IMPORT_PATH="/app/music/downloads" # Innerhalb des Docker Containers
CHECK_INTERVAL=30 # Zeit in Sekunden
LOCK_FILE="/tmp/m3u_script.lock"

# Funktion zum Aktualisieren der M3U-Datei
update_m3u_file() {
    local m3u_file="$1"
    local new_m3u_file="$NEW_M3U_FOLDER/$(basename "$m3u_file")"
    mkdir -p "$(dirname "$new_m3u_file")"

    while IFS= read -r line; do
        if [[ "$line" == *.mp3 ]]; then
            local title=$(basename "$line")
            local mp3_file="$M3U_FOLDER/$title"

            # Importiere die Datei mit Beets (single track import)
            docker exec "$CONTAINER_NAME" beet import -s "$IMPORT_PATH/$title"
            sleep 1

            # Hole den neuen Pfad aus Beets
            local new_path=$(docker exec "$CONTAINER_NAME" beet ls -f '$path' "$title" | tail -n 1)

            # Relativen Pfad für die Playlist berechnen
            local relative_path="${new_path#"$NEW_M3U_FOLDER"/}"
            echo "$relative_path" >> "$new_m3u_file"
        else
            echo "$line" >> "$new_m3u_file"
        fi
    done < "$m3u_file"
}

# Funktion zum Überprüfen der letzten Änderung
check_recent_changes() {
    local folder="$1"
    local interval="$2"
    local recent_changes=$(find "$folder" -type f -mmin -$((interval / 60)))
    if [ -n "$recent_changes" ]; then
        echo "Es wurden kürzlich Änderungen vorgenommen. Skript wird beendet."
        exit 1
    fi
}

# Funktion zum Erstellen und Überprüfen der Lock-Datei
create_lock() {
    if [ -e "$LOCK_FILE" ]; then
        echo "Skript läuft bereits. Beende."
        exit 1
    else
        touch "$LOCK_FILE"
    fi
}

# Funktion zum Entfernen der Lock-Datei
remove_lock() {
    rm -f "$LOCK_FILE"
}

# Hauptfunktion
main() {
    create_lock

    check_recent_changes "$M3U_FOLDER" "$CHECK_INTERVAL"

    shopt -s nullglob
    m3u_files=("$M3U_FOLDER"/*.m3u)
    shopt -u nullglob

    if ! [ ${#m3u_files[@]} -eq 0 ]; then      
        for m3u_file in "${m3u_files[@]}"; do
            update_m3u_file "$m3u_file"
            rm "$m3u_file"
        done
    fi

    # Importiere alle neuen Titel nach der Playlist-Aktualisierung
    docker exec "$CONTAINER_NAME" beet import -s "$IMPORT_PATH"

    remove_lock
}

trap remove_lock EXIT
main
