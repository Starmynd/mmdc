#!/bin/bash
#
# mmdc - MP3 metadata cleaner.
#
# Recursively scans the script's directory for MP3 files and tidies up
# the common tag junk that breaks library views:
#   - strips "feat." / "ft." from artist and title
#   - strips "[...]" tags and "remix" tails from titles
#   - strips "(... Edition)", "Deluxe", "Bonus" from album names
#   - normalizes "Various*" album artist to "Various Artists"
#   - collapses Hip-Hop/Trap/Rap genre spellings to "Hip-Hop"
#   - removes embedded cover art (APIC)
#
# Requires id3v2 (brew install id3v2 / apt install id3v2).
# The script modifies files in place - run it on a copy if unsure.

set -u

# ANSI color codes for readable output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
NC='\033[0m' # reset

# Output markers
CHECK="✔"
ARROW="➜"
ERROR="✖"

declare -a CHANGED_FILES

if ! command -v id3v2 &> /dev/null; then
    echo -e "${RED}${ERROR} id3v2 is required. Install it: brew install id3v2${NC}"
    exit 1
fi

# operate on the directory the script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}== MP3 Metadata Cleaner ==${NC}"
echo -e "Scanning: ${CYAN}$SCRIPT_DIR${NC}\n"

# every MP3 below the script dir, skipping macOS resource-fork junk (._*)
find "$SCRIPT_DIR" -type f -iname "*.mp3" -not -name "._*" | while IFS= read -r file; do

    if [ ! -w "$file" ]; then
        echo -e "${RED}${ERROR} No write permission: ${CYAN}$(basename "$file")${NC}"
        continue
    fi

    echo -e "${YELLOW}${ARROW} $(basename "$file")${NC}"

    changed=false

    ####### ARTIST (TPE1) ########
    artist=$(id3v2 -l "$file" | grep -E "TPE1" | sed -E 's/.*: (.*)/\1/')
    clean_artist=$(echo "$artist" | sed -E 's/[[:space:]]*(feat\.?|ft\.?)[[:space:]].*//i' | sed -E 's/[[:space:]]*$//')
    if [ "$artist" != "$clean_artist" ]; then
        id3v2 -a "$clean_artist" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### TITLE (TIT2) ########
    title=$(id3v2 -l "$file" | grep -E "TIT2" | sed -E 's/.*: (.*)/\1/')
    clean_title=$(echo "$title" | sed -E 's/(feat\.?|ft\.?|remix|\[.*\]).*//i' | sed -E 's/[[:space:]]*$//')
    if [ "$title" != "$clean_title" ]; then
        id3v2 -t "$clean_title" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ALBUM (TALB) ########
    album=$(id3v2 -l "$file" | grep -E "TALB" | sed -E 's/.*: (.*)/\1/')
    clean_album=$(echo "$album" | sed -E 's/ *(\(.*Edition\)|Deluxe|Bonus).*//i' | sed -E 's/[[:space:]]*$//')
    if [ "$album" != "$clean_album" ]; then
        id3v2 -A "$clean_album" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ALBUM ARTIST (TPE2) ########
    album_artist=$(id3v2 -l "$file" | grep -E "TPE2" | sed -E 's/.*: (.*)/\1/')
    if [[ "$album_artist" =~ Various ]]; then
        id3v2 --TPE2 "Various Artists" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### GENRE (TCON) ########
    genre=$(id3v2 -l "$file" | grep -E "TCON" | sed -E 's/.*: (.*)/\1/')
    if [[ "$genre" =~ (Hip[- ]?Hop|Trap|Rap) ]]; then
        id3v2 -g "Hip-Hop" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### COVER ART (APIC) ########
    if id3v2 -d "$file" | grep -q "APIC"; then
        id3v2 -D "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### PER-FILE VERDICT ########
    if [ "$changed" = true ]; then
        CHANGED_FILES+=("$file")
        echo -e "  ${GREEN}${CHECK} Cleaned and updated${NC}"
    else
        echo -e "  ${YELLOW}${ARROW} No changes${NC}"
    fi
done

########## SUMMARY ##########
echo -e "\n${BLUE}== Done ==${NC}"

if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}${ARROW} No files were changed.${NC}"
else
    echo -e "${GREEN}${CHECK} Changed files:${NC}"
    for file in "${CHANGED_FILES[@]}"; do
        echo -e "  ${CYAN}${file}${NC}"
    done
    echo -e "${GREEN}${CHECK} Total: ${#CHANGED_FILES[@]}${NC}"
fi
