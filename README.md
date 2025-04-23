# 🎵 MP3 Metadata Cleaner

A simple yet powerful Bash script that cleans up messy ID3 tags in your `.mp3` files.  
Removes junk like "feat.", "remix", unnecessary album info, and embedded album art — all with a single command.

---

## 🚀 Features

- Cleans **Artist** tag (`TPE1`) — removes "feat.", "ft.", etc.
- Cleans **Title** tag (`TIT2`) — removes "feat.", "remix", `[Explicit]`, etc.
- Cleans **Album** tag (`TALB`) — strips out "(Deluxe Edition)", "Bonus", etc.
- Normalizes **Album Artist** (`TPE2`) — replaces "Various" with "Various Artists"
- Simplifies **Genre** tag (`TCON`) — unifies similar genres under "Hip-Hop"
- Removes **Embedded Cover Art** (`APIC`) — to reduce file size
- Outputs a colorful summary with clear success/error indicators

---

## 📦 Requirements

- `id3v2` must be installed  
  **macOS:**  
  ```bash
  brew install id3v2
📂 How It Works
The script scans the current folder and all subfolders for .mp3 files and performs the following:

Reads current metadata using id3v2

Cleans or replaces values in-place

Removes embedded album art if present

Logs every change with nice colored output

🔧 Usage
bash
Copy
Edit
bash fix_metadata.sh
No arguments needed. Just run the script in any folder containing MP3s.
You can also place it in /usr/local/bin and call it globally.

📑 Example
Before:

Title: Eminem feat. 50 Cent [Explicit Remix]

Album: Curtain Call (Deluxe Edition)

Genre: Hip-Hop/Rap/Trap

Cover: Embedded

After:

Title: Eminem

Album: Curtain Call

Genre: Hip-Hop

Cover: Removed

⚠️ Notes
Do not run as root unless you get permission errors

Backup your files if you're worried about permanent changes

Script doesn't rename files — only updates internal metadata

🧪 License
MIT — do whatever you want, just don’t blame me if your metadata explodes.

👨‍💻 Author
Dorrell Starmynd
