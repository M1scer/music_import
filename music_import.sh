#!/bin/bash
set -e

### Konfiguration ###
MUSIC_DIR="/music/library"         # Hauptverzeichnis
BEET_CMD="beet"                    # Dein Beets-Kommando
QUIET_WAIT=30                      # Sekunden ohne Änderung
LOCKFILE="/tmp/beets_import.lock"  # Lock-Datei verhindert parallele Ausführungen


# Lock-Mechanismus
if [ -e "$LOCKFILE" ]; then
    echo "⚠️  Skript läuft bereits (Lockfile $LOCKFILE existiert)."
    exit 1
fi
# Lock anlegen und bei Exit löschen
trap 'rm -f "$LOCKFILE"' EXIT
touch "$LOCKFILE"

# 1. Prüfen auf kürzliche Änderungen (nur Dateien)
echo "⏱️  Prüfe, ob in $MUSIC_DIR in den letzten $QUIET_WAIT s Änderungen passiert sind (Dateien)..."
# Berechne Zeitpunkt QUIET_WAIT Sekunden zuvor
cutoff=$(date -d "-$QUIET_WAIT seconds" '+%Y-%m-%d %H:%M:%S')
# Suche nach Dateien im Hauptverzeichnis, die neuer sind als cutoff
recent_changes=$(find "$MUSIC_DIR" -maxdepth 1 -type f -newermt "$cutoff")

if [ -n "$recent_changes" ]; then
    echo "❌ Es wurden kürzlich Änderungen an Dateien vorgenommen. Skript wird beendet."
    exit 1
fi

echo "✅ Keine Dateiänderungen in den letzten $QUIET_WAIT s – fahre mit Import fort."


# 2. Importiere alle Dateien im Hauptverzeichnis (ohne Unterverzeichnisse) als Singletons
mapfile -d '' files < <(find "$MUSIC_DIR" -maxdepth 1 -type f \
  \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.ogg' \) -print0)

if [ ${#files[@]} -eq 0 ]; then
    echo "ℹ️  Keine Dateien zum Importieren in $MUSIC_DIR gefunden."
else
    echo "📥  Importiere folgende Dateien als Singletons:"
    for f in "${files[@]}"; do
        echo "   • $f"
    done
    # Dateien übergeben an beet import -s
    printf '%s\0' "${files[@]}" | xargs -0 $BEET_CMD import -s

    # 3. Verschiebe alle importierten Dateien in die Library
    echo "🚚  Verschiebe Dateien aus $MUSIC_DIR in die Beets-Library ..."
    $BEET_CMD move -d $MUSIC_DIR

    echo "🎉  Fertig! Alle Dateien importiert und verschoben."

fi
