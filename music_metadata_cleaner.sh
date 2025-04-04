#!/bin/bash

# Music Collection Organizer - Verbose Version
# Organizes music into /Music/Artist/Album (year)/songs
# Cleans up special characters and normalizes metadata
# Shows detailed progress in real-time
# 
# GitHub: https://github.com/starmynd/mmdc
# License: MIT

# Version
VERSION="3.1.0"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global counters
processed_count=0
update_success=0
renamed_folders=0
renamed_files=0
organized_albums=0

# Function to display script information
show_info() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "    Music Collection Organizer v$VERSION      "
    echo "=============================================="
    echo -e "${NC}"
    echo "This script:"
    echo "1. Organizes everything into /Music/Artist/Album (year)/songs format"
    echo "2. Cleans up special characters like % and _"
    echo "3. Updates metadata to match the folder structure"
    echo ""
}

# Function to check the system
check_system() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}Error: This script only works on macOS${NC}"
        exit 1
    fi
    echo -e "${GREEN}System check: macOS detected${NC}"
}

# Temporary files
temp_file=$(mktemp)
renamed_folders_list=$(mktemp)
organized_albums_list=$(mktemp)

# Function to show timestamp
timestamp() {
    date "+%H:%M:%S"
}

# Function to clean text by removing special characters
clean_text() {
    local text="$1"
    
    # Replace underscores with spaces
    text="${text//_/ }"
    
    # Remove or replace special characters
    text="${text//%/ }"
    text="${text//\[/\(}"
    text="${text//\]/\)}"
    
    # Remove multiple spaces
    text=$(echo "$text" | sed 's/  */ /g')
    
    # Trim leading and trailing spaces
    text=$(echo "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    echo "$text"
}

# Function to extract the year from a string
extract_year() {
    local text="$1"
    local year=""
    
    # Try to find year in parentheses
    if [[ $text =~ \(([0-9]{4})\) ]]; then
        year="${BASH_REMATCH[1]}"
    # Try to find year at the end
    elif [[ $text =~ ([0-9]{4})$ ]]; then
        year="${BASH_REMATCH[1]}"
    # Try to find any 4-digit year between 1900-2025
    elif [[ $text =~ ([0-9]{4}) ]] && [[ ${BASH_REMATCH[1]} -ge 1900 ]] && [[ ${BASH_REMATCH[1]} -le 2025 ]]; then
        year="${BASH_REMATCH[1]}"
    fi
    
    echo "$year"
}

# Function to extract the main artist
extract_main_artist() {
    local artist="$1"
    
    # Clean up the artist string - remove leading/trailing whitespace and newlines
    artist=$(echo "$artist" | tr -d '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # Remove everything after "feat", "ft.", "featuring", "&", "and", etc.
    if [[ "$artist" == *" feat "* ]]; then
        echo "${artist%% feat *}"
    elif [[ "$artist" == *" feat. "* ]]; then
        echo "${artist%% feat. *}"
    elif [[ "$artist" == *" ft "* ]]; then
        echo "${artist%% ft *}"
    elif [[ "$artist" == *" ft. "* ]]; then
        echo "${artist%% ft. *}"
    elif [[ "$artist" == *" featuring "* ]]; then
        echo "${artist%% featuring *}"
    elif [[ "$artist" == *" & "* ]]; then
        echo "${artist%% & *}"
    elif [[ "$artist" == *"&"* ]]; then
        echo "${artist%%&*}"
    elif [[ "$artist" == *" and "* ]]; then
        echo "${artist%% and *}"
    elif [[ "$artist" == *" AND "* ]]; then
        echo "${artist%% AND *}"
    elif [[ "$artist" == *" And "* ]]; then
        echo "${artist%% And *}"
    elif [[ "$artist" == *" with "* ]]; then
        echo "${artist%% with *}"
    elif [[ "$artist" == *" WITH "* ]]; then
        echo "${artist%% WITH *}"
    elif [[ "$artist" == *" With "* ]]; then
        echo "${artist%% With *}"
    elif [[ "$artist" == *" vs "* ]]; then
        echo "${artist%% vs *}"
    elif [[ "$artist" == *" VS "* ]]; then
        echo "${artist%% VS *}"
    elif [[ "$artist" == *" vs. "* ]]; then
        echo "${artist%% vs. *}"
    elif [[ "$artist" == *","* ]]; then
        echo "${artist%%,*}"
    else
        echo "$artist"
    fi
}

# Function to update metadata using built-in mdls and xattr
update_metadata() {
    local file="$1"
    local new_artist="$2"
    local new_album="$3"
    local new_year="$4"
    
    echo -e "${CYAN}[$(timestamp)] Updating metadata for: $(basename "$file")${NC}"
    
    # Update artist metadata
    if [ -n "$new_artist" ]; then
        echo -e "${CYAN}[$(timestamp)]   Setting artist: $new_artist${NC}"
        xattr -w com.apple.metadata:kMDItemAuthors "$new_artist" "$file" 2>/dev/null
    fi
    
    # Update album metadata
    if [ -n "$new_album" ]; then
        echo -e "${CYAN}[$(timestamp)]   Setting album: $new_album${NC}"
        xattr -w com.apple.metadata:kMDItemAlbum "$new_album" "$file" 2>/dev/null
    fi
    
    # Update year metadata
    if [ -n "$new_year" ]; then
        echo -e "${CYAN}[$(timestamp)]   Setting year: $new_year${NC}"
        xattr -w com.apple.metadata:kMDItemRecordingYear "$new_year" "$file" 2>/dev/null
    fi
    
    return 0
}

# Alternative ways to get artist metadata
try_get_artist() {
    local file="$1"
    local artist=""
    
    echo -e "${CYAN}[$(timestamp)] Extracting artist info for: $(basename "$file")${NC}"
    
    # Try the main macOS metadata
    artist=$(mdls -name kMDItemAuthors "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
    
    if [ -n "$artist" ]; then
        echo -e "${CYAN}[$(timestamp)]   Found in metadata: $artist${NC}"
    else
        # If that fails, try other potential metadata fields
        artist=$(mdls -name kMDItemAuthor "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
        
        if [ -n "$artist" ]; then
            echo -e "${CYAN}[$(timestamp)]   Found in author field: $artist${NC}"
        else
            # Try to get from the filename if it follows "Artist - Title" format
            filename=$(basename "$file")
            if [[ "$filename" == *" - "* ]]; then
                artist="${filename%% - *}"
                echo -e "${CYAN}[$(timestamp)]   Extracted from filename: $artist${NC}"
            else
                # Try parent directory name as a last resort
                parent_dir=$(basename "$(dirname "$file")")
                if [[ "$parent_dir" != "." && "$parent_dir" != "/" ]]; then
                    artist="$parent_dir"
                    echo -e "${CYAN}[$(timestamp)]   Using parent directory: $artist${NC}"
                else
                    echo -e "${CYAN}[$(timestamp)]   Could not determine artist${NC}"
                fi
            fi
        fi
    fi
    
    echo "$artist"
}

# Function to clean up artist folder names
clean_artist_folder_name() {
    local folder_name="$1"
    
    echo -e "${CYAN}[$(timestamp)] Cleaning artist name: $folder_name${NC}"
    
    # Strip " - Discography" from folder names
    if [[ "$folder_name" == *" - Discography"* ]]; then
        folder_name="${folder_name%% - Discography*}"
        echo -e "${CYAN}[$(timestamp)]   Removed 'Discography' suffix${NC}"
    fi
    
    # Strip " - discography" from folder names (lowercase)
    if [[ "$folder_name" == *" - discography"* ]]; then
        folder_name="${folder_name%% - discography*}"
        echo -e "${CYAN}[$(timestamp)]   Removed 'discography' suffix${NC}"
    fi
    
    # Clean up the folder name
    local cleaned=$(clean_text "$folder_name")
    
    if [ "$folder_name" != "$cleaned" ]; then
        echo -e "${CYAN}[$(timestamp)]   Cleaned special characters: $cleaned${NC}"
    fi
    
    # Return the cleaned name
    echo "$cleaned"
}

# Function to create proper album folder with year
create_album_folder_with_year() {
    local artist="$1"
    local album="$2"
    local year="$3"
    local base_dir="$4"
    
    echo -e "${MAGENTA}[$(timestamp)] Creating album structure for: $album${NC}"
    
    # Clean artist and album names
    local clean_artist=$(clean_artist_folder_name "$artist")
    local clean_album=$(clean_text "$album")
    
    echo -e "${MAGENTA}[$(timestamp)]   Artist: $clean_artist${NC}"
    echo -e "${MAGENTA}[$(timestamp)]   Album: $clean_album${NC}"
    if [ -n "$year" ]; then
        echo -e "${MAGENTA}[$(timestamp)]   Year: $year${NC}"
    fi
    
    # Create artist folder path
    local artist_path="$base_dir/$clean_artist"
    
    # Create album folder name with year if available
    local album_folder="$clean_album"
    if [ -n "$year" ]; then
        album_folder="$clean_album ($year)"
    fi
    
    # Create full album path
    local album_path="$artist_path/$album_folder"
    
    echo -e "${MAGENTA}[$(timestamp)]   Creating directory: $album_path${NC}"
    
    # Create artist folder if it doesn't exist
    if [ ! -d "$artist_path" ]; then
        echo -e "${MAGENTA}[$(timestamp)]   Creating artist folder: $clean_artist${NC}"
        mkdir -p "$artist_path" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[$(timestamp)] Error creating artist folder: $artist_path${NC}" >&2
            return 1
        fi
    fi
    
    # Create album folder if it doesn't exist
    if [ ! -d "$album_path" ]; then
        echo -e "${MAGENTA}[$(timestamp)]   Creating album folder: $album_folder${NC}"
        mkdir -p "$album_path" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[$(timestamp)] Error creating album folder: $album_path${NC}" >&2
            return 1
        fi
    fi
    
    # Return the album path
    echo "$album_path"
}

# Function to organize music files
organize_music_files() {
    local dir="$1"
    local base_dir="${dir%/}/Music"  # Create or use a Music folder in the provided directory
    
    echo -e "${YELLOW}[$(timestamp)] Organizing music files into $base_dir...${NC}"
    
    # Create base Music directory if it doesn't exist
    if [ ! -d "$base_dir" ]; then
        echo -e "${YELLOW}[$(timestamp)] Creating base Music folder${NC}"
        mkdir -p "$base_dir" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[$(timestamp)] Error creating base Music folder: $base_dir${NC}" >&2
            return 1
        fi
    fi
    
    # Find all music files
    echo -e "${YELLOW}[$(timestamp)] Finding all music files...${NC}"
    
    # Create a temporary file to store the list of music files
    music_files_list=$(mktemp)
    echo -e "${YELLOW}[$(timestamp)] Searching for MP3, M4A, and AAC files...${NC}"
    
    # Do the find command with verbose output
    find "$dir" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.aac" \) > "$music_files_list" &
    find_pid=$!
    
    # Show progress while find is running
    while kill -0 $find_pid 2>/dev/null; do
        echo -e "${YELLOW}[$(timestamp)] Still searching for files...${NC}"
        sleep 2
    done
    
    # Count total files
    total_files=$(wc -l < "$music_files_list")
    echo -e "${BLUE}[$(timestamp)] Found $total_files music files to process${NC}"
    
    # Process each file
    file_number=0
    while IFS= read -r file; do
        file_number=$((file_number + 1))
        
        # Always show which file is being processed
        echo -e "${YELLOW}[$(timestamp)] Processing file $file_number/$total_files: $file${NC}"
        
        # Skip macOS hidden files
        if [[ "$(basename "$file")" == .* ]]; then
            echo -e "${YELLOW}[$(timestamp)]   Skipping hidden file${NC}"
            continue
        fi
        
        # Get file name and extension
        filename=$(basename "$file")
        extension="${filename##*.}"
        echo -e "${YELLOW}[$(timestamp)]   File extension: $extension${NC}"
        
        # Try to get artist, album, and year from metadata or folder structure
        current_artist=$(try_get_artist "$file")
        echo -e "${YELLOW}[$(timestamp)]   Extracting album info...${NC}"
        current_album=$(mdls -name kMDItemAlbum "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
        
        if [ -n "$current_album" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Album from metadata: $current_album${NC}"
        else
            echo -e "${YELLOW}[$(timestamp)]   Album not found in metadata${NC}"
        fi
        
        echo -e "${YELLOW}[$(timestamp)]   Extracting year info...${NC}"
        current_year=$(mdls -name kMDItemRecordingYear "$file" 2>/dev/null | grep -v "(null)" | sed 's/[^0-9]//g')
        
        if [ -n "$current_year" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Year from metadata: $current_year${NC}"
        else
            echo -e "${YELLOW}[$(timestamp)]   Year not found in metadata${NC}"
        fi
        
        # If artist not found in metadata, try to extract from folder structure
        if [ -z "$current_artist" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Trying to extract artist from folder structure...${NC}"
            # Try parent directory
            parent_dir=$(basename "$(dirname "$file")")
            if [[ "$parent_dir" == *" - "* ]]; then
                current_artist="${parent_dir%% - *}"
                echo -e "${YELLOW}[$(timestamp)]   Found artist in parent directory: $current_artist${NC}"
            else
                current_artist="$parent_dir"
                echo -e "${YELLOW}[$(timestamp)]   Using parent directory as artist: $current_artist${NC}"
            fi
        fi
        
        # Clean and extract the main artist
        echo -e "${YELLOW}[$(timestamp)]   Cleaning artist name...${NC}"
        current_artist=$(clean_text "$current_artist")
        main_artist=$(extract_main_artist "$current_artist")
        
        if [ "$current_artist" != "$main_artist" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Extracted main artist: $main_artist${NC}"
        fi
        
        # If album not found in metadata, try to extract from folder structure
        if [ -z "$current_album" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Trying to extract album from folder structure...${NC}"
            # Try parent directory
            parent_dir=$(basename "$(dirname "$file")")
            if [[ "$parent_dir" == *" - "* ]]; then
                current_album="${parent_dir##* - }"
                echo -e "${YELLOW}[$(timestamp)]   Found album in parent directory: $current_album${NC}"
            else
                # Try grandparent directory if parent is likely the artist
                grandparent_dir=$(basename "$(dirname "$(dirname "$file")")")
                if [[ "$grandparent_dir" == *" - "* ]]; then
                    current_album="${grandparent_dir##* - }"
                    echo -e "${YELLOW}[$(timestamp)]   Found album in grandparent directory: $current_album${NC}"
                else
                    # Default to Unknown Album
                    current_album="Unknown Album"
                    echo -e "${YELLOW}[$(timestamp)]   Using default: Unknown Album${NC}"
                fi
            fi
        fi
        
        # Clean album name
        echo -e "${YELLOW}[$(timestamp)]   Cleaning album name...${NC}"
        current_album=$(clean_text "$current_album")
        
        # If year not found in metadata, try to extract from album name or folder
        if [ -z "$current_year" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Trying to extract year from names...${NC}"
            # Try to extract from album name
            current_year=$(extract_year "$current_album")
            
            if [ -n "$current_year" ]; then
                echo -e "${YELLOW}[$(timestamp)]   Found year in album name: $current_year${NC}"
            else
                # Try parent directory
                parent_dir=$(basename "$(dirname "$file")")
                current_year=$(extract_year "$parent_dir")
                
                if [ -n "$current_year" ]; then
                    echo -e "${YELLOW}[$(timestamp)]   Found year in parent directory: $current_year${NC}"
                else
                    # Try grandparent directory
                    grandparent_dir=$(basename "$(dirname "$(dirname "$file")")")
                    current_year=$(extract_year "$grandparent_dir")
                    
                    if [ -n "$current_year" ]; then
                        echo -e "${YELLOW}[$(timestamp)]   Found year in grandparent directory: $current_year${NC}"
                    else
                        echo -e "${YELLOW}[$(timestamp)]   Could not determine year${NC}"
                    fi
                fi
            fi
        fi
        
        # Remove year from album name if it's already in parentheses
        if [ -n "$current_year" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Removing year from album name if present...${NC}"
            current_album=$(echo "$current_album" | sed -E "s/ *\($current_year\) *//")
        fi
        
        # Create the proper album folder structure
        echo -e "${YELLOW}[$(timestamp)]   Creating album folder structure...${NC}"
        album_path=$(create_album_folder_with_year "$main_artist" "$current_album" "$current_year" "$base_dir")
        
        if [ -z "$album_path" ]; then
            echo -e "${RED}[$(timestamp)] Error creating album path for: $file${NC}" >&2
            continue
        fi
        
        # Clean up the file name
        echo -e "${YELLOW}[$(timestamp)]   Getting track title...${NC}"
        track_title=$(mdls -name kMDItemTitle "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
        
        if [ -n "$track_title" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Track title from metadata: $track_title${NC}"
        else
            echo -e "${YELLOW}[$(timestamp)]   Extracting track title from filename...${NC}"
            # Try to extract from filename
            if [[ "$filename" == *" - "* ]]; then
                track_title="${filename##* - }"
                track_title="${track_title%.*}"
                echo -e "${YELLOW}[$(timestamp)]   Extracted from filename: $track_title${NC}"
            else
                track_title="${filename%.*}"
                echo -e "${YELLOW}[$(timestamp)]   Using filename as title: $track_title${NC}"
            fi
        fi
        
        echo -e "${YELLOW}[$(timestamp)]   Cleaning track title...${NC}"
        track_title=$(clean_text "$track_title")
        clean_filename="$track_title.$extension"
        
        # Create the destination path
        destination="$album_path/$clean_filename"
        echo -e "${YELLOW}[$(timestamp)]   Destination: $destination${NC}"
        
        # Create a unique filename if a file with the same name already exists
        if [ -f "$destination" ]; then
            echo -e "${YELLOW}[$(timestamp)]   Destination file already exists, creating unique name...${NC}"
            counter=1
            while [ -f "$album_path/$track_title ($counter).$extension" ]; do
                counter=$((counter + 1))
            done
            destination="$album_path/$track_title ($counter).$extension"
            echo -e "${YELLOW}[$(timestamp)]   New destination: $destination${NC}"
        fi
        
        # Move the file to the new location
        if [ "$file" != "$destination" ]; then
            echo -e "${GREEN}[$(timestamp)]   Copying file...${NC}"
            # Create a copy instead of moving to preserve originals
            cp "$file" "$destination" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                # Update metadata for the copied file
                update_metadata "$destination" "$main_artist" "$current_album" "$current_year"
                
                echo -e "${GREEN}[$(timestamp)] Successfully organized: ${NC}"
                echo -e "${GREEN}[$(timestamp)]   From: $filename${NC}"
                echo -e "${GREEN}[$(timestamp)]   To: $main_artist/$current_album"
                if [ -n "$current_year" ]; then
                    echo -e "${GREEN}[$(timestamp)]      ($current_year)${NC}"
                fi
                echo -e "${GREEN}[$(timestamp)]      /$clean_filename${NC}"
                
                # Update counter
                organized_albums=$((organized_albums + 1))
            else
                echo -e "${RED}[$(timestamp)] Error copying file: $file${NC}" >&2
            fi
        fi
        
        # Show progress as a percentage
        progress=$((file_number * 100 / total_files))
        echo -e "${BLUE}[$(timestamp)] Progress: $progress% complete ($file_number/$total_files)${NC}"
        echo ""  # Add a blank line for better readability
    done < "$music_files_list"
    
    # Clean up
    rm -f "$music_files_list"
}

# Main function
main() {
    show_info
    check_system
    
    # Determine directory to process
    local dir="."
    if [ $# -gt 0 ]; then
        dir="$1"
    fi
    
    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo -e "${RED}[$(timestamp)] Error: Directory '$dir' does not exist${NC}" >&2
        exit 1
    fi
    
    echo -e "${BLUE}[$(timestamp)] Starting organization process...${NC}"
    
    # Organize music files
    organize_music_files "$dir"
    
    echo ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}[$(timestamp)] Organization complete.${NC}"
    echo -e "${GREEN}[$(timestamp)]   Music files organized: $organized_albums${NC}"
    echo -e "${BLUE}======================================================${NC}"
    
    # Remove temporary files
    rm -f "$temp_file" "$renamed_folders_list" "$organized_albums_list"
    
    echo ""
    echo -e "${YELLOW}[$(timestamp)] NOTE: This script created copies of your music files in the new structure.${NC}"
    echo -e "${YELLOW}[$(timestamp)] Original files were preserved. Once you confirm everything is correct,${NC}"
    echo -e "${YELLOW}[$(timestamp)] you can delete the original files to save space.${NC}"
}

# Make sure output is unbuffered
exec 1=>(stdbuf -i0 -o0 -e0 cat)

# Run main function
main "$@"
