# mmdc - MP3 Metadata Cleaner

A single-file bash script that cleans up messy ID3 tags in `.mp3`
files: strips "feat."/"remix" junk, edition suffixes and embedded
cover art in one pass. Requires only `id3v2`.

## What it cleans

| Tag  | Rule                                                        |
|------|-------------------------------------------------------------|
| TPE1 | remove trailing `feat. X` / `ft. X` from artist             |
| TIT2 | remove `feat.`, `remix`, `[Explicit]`-style brackets        |
| TALB | remove `(Deluxe Edition)`, `Bonus`, `... Edition` suffixes  |
| TPE2 | normalize `Various*` album artist to `Various Artists`      |
| TCON | collapse `Hip-Hop/Rap/Trap` spellings to `Hip-Hop`          |
| APIC | delete embedded cover art (smaller files, cleaner libraries) |

## Usage

```console
$ brew install id3v2        # or: apt install id3v2
$ bash music_metadata_cleaner.sh
== MP3 Metadata Cleaner ==
Scanning: /Volumes/music/incoming

➜ 01-track.mp3
  ✔ Cleaned and updated
➜ 02-track.mp3
  ➜ No changes

== Done ==
✔ Changed files:
  /Volumes/music/incoming/01-track.mp3
✔ Total: 1
```

The script operates on the directory it lives in, recursing through
subfolders (macOS `._*` resource-fork files are skipped). Changes are
in place and logged with colored output; a summary lists everything
touched.

## Example

```
Before                                   After
Title:  Nightcall (Kavinsky feat. A)     Title:  Nightcall
Artist: Kavinsky feat. A                 Artist: Kavinsky
Album:  OutRun (Deluxe Edition)          Album:  OutRun
Genre:  Hip-Hop/Rap/Trap                 Genre:  Hip-Hop
Cover:  embedded                         Cover:  removed
```

## Notes

- Tags only - files are never renamed or moved.
- Changes are immediate; test on a copy if the library is precious.
- Read-only checks still require `id3v2` in `PATH`.

## License

MIT
