# Music Metadata Cleaner

A utility script for cleaning music file metadata by removing additional artists.

## Description

This script automatically processes music file metadata (MP3, M4A, AAC), removing all additional artists from the artist name that appear after "feat", "ft.", "featuring", "&" or commas.

For example:
- "Pharrell feat Snoop Dogg" → "Pharrell"
- "Rihanna ft. Drake" → "Rihanna"
- "Taylor Swift & Ed Sheeran" → "Taylor Swift"

## Requirements

- macOS 10.13 or newer (but could be working on linux)
- Terminal

## Installation

```bash
# Clone the repository
git clone https://github.com/starmynd/mmdc.git

# Navigate to the project directory
cd mmdc

# Make the script executable
chmod +x music_metadata_cleaner.sh
```

## Usage

1. Navigate to the folder with music files you want to process:

```bash
cd /path/to/your/music/folder
```

2. Run the script:

```bash
/path/to/music_metadata_cleaner.sh
```

You can also specify a directory to process:

```bash
/path/to/music_metadata_cleaner.sh /path/to/music/directory
```

## Output

After the script completes, it will display:
1. The total number of processed files
2. A complete list of modified tracks in the format:
   ```
   Original Artist - Track Title → New Artist - Track Title
   ```

## How It Works

The script uses built-in macOS utilities:
- `mdls` to retrieve current file metadata
- `xattr` to modify the metadata

The script only changes file metadata, it does not alter the audio content.

## License

[MIT](LICENSE)

## Author

Starmynd

## Contributing

Contributions are welcome! Please check out the [contribution guidelines](CONTRIBUTING.md).
