# Music Collection Organizer

A powerful and flexible tool to automatically organize your music collection into a standardized format with clean metadata.

## Features

- **Complete Collection Organization**: Transforms your messy music folders into a clean, standardized structure
- **Consistent Format**: Organizes everything into `/Music/Artist/Album (year)/songs`
- **Metadata Cleanup**: Removes "feat", "ft.", "featuring", and other unnecessary information from artist names
- **Special Character Handling**: Converts underscores, percentages, and other special characters into proper spaces
- **Real-time Progress**: Displays detailed information about every action being performed
- **Safe Operation**: Creates copies of your music files rather than moving them, allowing you to verify the results

## Requirements

- macOS 10.13 or newer
- Terminal access
- Bash shell

## Installation

1. Download the script:
```
git clone https://github.com/starmynd/mmdc.git
cd mmdc
```

2. Make the script executable:
```
chmod +x verbose_music_organizer.sh
```

## Usage

1. Navigate to the directory containing your disorganized music collection:
```
cd /path/to/your/music/folder
```

2. Run the script:
```
/path/to/verbose_music_organizer.sh
```

3. The script will:
   - Search for all music files (MP3, M4A, AAC)
   - Extract artist, album, and year information from file metadata and folder names
   - Create a properly organized folder structure
   - Copy files to their new locations with clean names
   - Update metadata to match folder structure

4. After completion, verify that everything is organized correctly, then you can safely delete the original files to save space.

## Examples

### Before:
```
/Music
    └── (2022) Moondial - HATTORI (EP)
    └── (2001) Nate Dogg - Nate Dogg & Friends
    └── D'Angelo-The_Best_So_Far-2008-RAGEMP3
    └── 50 CENT
    └── 6LACK - Discography
    └── Justin Timberlake - FutureSex%LoveSounds
    └── Justin Timberlake - Justified
```

### After:
```
/Music
    └── Moondial
        └── HATTORI (2022)
            └── [clean song files]
    └── Nate Dogg
        └── Nate Dogg Friends (2001)
            └── [clean song files]
    └── D'Angelo
        └── The Best So Far (2008)
            └── [clean song files]
    └── 50 CENT
        └── Unknown Album
            └── [clean song files]
    └── 6LACK
        └── [album folders]
            └── [clean song files]
    └── Justin Timberlake
        └── FutureSex LoveSounds
            └── [clean song files]
        └── Justified
            └── [clean song files]
```

## Customization

The script includes comprehensive logging that shows every action taken. You can customize the script by editing the following parts:

- **File Types**: Change the file extensions in the find command to support additional formats
- **Special Character Handling**: Modify the `clean_text` function to handle additional special characters
- **Metadata Fields**: Adjust the metadata fields that are updated in the `update_metadata` function

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

starmynd - https://github.com/starmynd

---

*Note: This script makes copies of your files rather than moving them. This provides a safety net but requires additional disk space during the organization process.*
