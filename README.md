# M3U Playlist Processor for Beets

This script processes `.m3u` playlist files by updating the file paths to match the format used in your Beets-managed music library. It then triggers Beets to import the newly referenced files.

## Features

- Reads and updates `.m3u` playlist files with relative paths based on MP3 metadata.
- Uses `ffprobe` and `jq` to extract metadata and transform paths accordingly.
- Automatically imports updated files into the Beets container using `beet import`.
- Prevents concurrent runs using a lock file.
- Skips execution if recent changes were made to the monitored directory.

## Requirements

- **Docker** (to run the `beets` container)
- A running **Beets** container (e.g. `beets` with `beet` command available inside)
- **jq** (for JSON parsing)
- **ffprobe** (usually provided by `ffmpeg`)
- Linux-based shell environment

## Configuration

You can customize the following variables inside the script:

```bash
M3U_FOLDER="/mnt/pve/media/music/downloads"         # Folder with incoming .m3u playlists
NEW_M3U_FOLDER="/mnt/pve/media/music/library/__playlists/" # Output folder for updated .m3u files
CONTAINER_NAME="beets"                              # Docker container name running Beets
IMPORT_PATH="/app/music/downloads"                  # Import path inside the Beets container
CHECK_INTERVAL=30                                   # Skip if changes within the last 30 seconds
LOCK_FILE="/tmp/m3u_script.lock"                    # Lock file to prevent parallel runs
```

## Usage

1. **Ensure all requirements are installed**:
    ```bash
    sudo apt install ffmpeg jq docker
    ```

2. **Adjust paths and container name** in the script as needed.

3. **Run the script**:
    ```bash
    ./process_m3u.sh
    ```

4. The script will:
    - Skip execution if the download folder was recently modified.
    - Update paths in `.m3u` files based on MP3 metadata.
    - Save updated playlists in the specified library folder.
    - Import the referenced music files into Beets via Docker.

## Notes

- This script assumes that `.m3u` files reference MP3s located in `$M3U_FOLDER`.
- Metadata extraction requires `album_artist` and `album` tags to be present.
- Paths in the new `.m3u` files will be relative (e.g., `../Artist/Album/Track.mp3`).
