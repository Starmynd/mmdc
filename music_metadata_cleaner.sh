#!/bin/bash

# Music Metadata Cleaner
# A script to clean music file metadata by removing additional artists
# Removes all mentions of "feat", "featuring", etc. from the artist name
# 
# GitHub: https://github.com/starmynd/mmdc
# License: MIT

# Version
VERSION="1.0.0"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display script information
show_info() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "         Music Metadata Cleaner v$VERSION     "
    echo "=============================================="
    echo -e "${NC}"
    echo "This script cleans music file metadata by removing"
    echo "additional artists after 'feat', 'ft.', '&', etc."
    echo ""
}

# Function to check the system
check_system() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}Error: This script only works on macOS${NC}"
        exit 1
    fi
}

# Temporary file to store the list of modified tracks
temp_file=$(mktemp)

# Function to extract the main artist
extract_main_artist() {
    local artist="$1"
    
    # Remove everything after "feat", "ft.", "featuring", "&" or comma
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
    
    # Use built-in xattr utility to update metadata
    xattr -w com.apple.metadata:kMDItemAuthors "$new_artist" "$file" 2>/dev/null
    return $?
}

# Function to process directory
process_directory() {
    local dir="$1"
    local processed_count=0
    
    echo -e "${YELLOW}Searching for music files in: $dir${NC}"
    
    # Find all music files in the specified directory and subdirectories
    find "$dir" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.aac" \) | while read file; do
        # Use built-in mdls utility to get metadata
        current_artist=$(mdls -name kMDItemAuthors "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
        track_title=$(mdls -name kMDItemTitle "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
        
        # If metadata retrieval failed, try another approach
        if [ -z "$current_artist" ]; then
            current_artist=$(mdls -name kMDItemAuthor "$file" 2>/dev/null | grep -v "(null)" | awk -F'"' '{print $2}')
        fi
        
        if [ -z "$track_title" ]; then
            # Try to get the title from the filename
            filename=$(basename "$file")
            track_title="${filename%.*}"
        fi
        
        # If tag was not found, skip the file
        if [ -z "$current_artist" ]; then
            echo -e "${RED}Skipping file $file: could not determine artist${NC}" >&2
            continue
        fi
        
        # Extract the main artist
        main_artist=$(extract_main_artist "$current_artist")
        
        # If the artist has changed, update the tag
        if [ "$current_artist" != "$main_artist" ]; then
            # Update metadata
            update_metadata "$file" "$main_artist"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Updated: $file${NC}"
                echo -e "  ${YELLOW}Artist:${NC} $current_artist ${BLUE}→${NC} $main_artist"
                
                # Write track information to temp file
                echo "$current_artist - $track_title → $main_artist - $track_title" >> "$temp_file"
                
                processed_count=$((processed_count + 1))
            else
                echo -e "${RED}Error updating metadata for $file${NC}" >&2
            fi
        fi
    done
    
    echo "$processed_count"
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
        echo -e "${RED}Error: Directory '$dir' does not exist${NC}" >&2
        exit 1
    fi
    
    echo "Starting file processing..."
    processed_count=$(process_directory "$dir")
    
    echo ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}Processing complete. Updated files: $processed_count${NC}"
    echo -e "${BLUE}======================================================${NC}"
    
    # If files were modified, display the list
    if [ $processed_count -gt 0 ]; then
        echo ""
        echo -e "${GREEN}List of modified tracks:${NC}"
        echo -e "${BLUE}------------------------------------------------------${NC}"
        cat "$temp_file" | sort
        echo -e "${BLUE}------------------------------------------------------${NC}"
    fi
    
    # Remove temporary file
    rm -f "$temp_file"
}

# Run main function
main "$@"
