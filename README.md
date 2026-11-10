# CD Collection Manager

A cross-platform desktop application built with **Lazarus / Free Pascal** and **SQLite3** for managing music CD collections and parsing XSPF audio playlists.

---

## 🚀 Features

HEAD
* **Library Stats:** Real-time tracking of active artists, total albums, and tracks in the status bar.  
* **XSPF Playlist Parser:** Import track listings directly with intelligent fallbacks for missing metadata (`Track X`, `Unknown Artist`).  
* **Cross-Platform:** Runs natively on Linux (Fedora, openSUSE) and Windows 11\.

## Getting Started
### Linux / macOS
1.Clone the repository to your local machine:
\`\`\`bash
git clone https://github.com/crazyram-uk/CD_CollectDB.git
\`\`\`

1. Open project1.lpi in Lazarus IDE.
2. Build (Shift + F9) and Run (F9).


---

## 🛠️ Prerequisites

### Linux (Fedora / openSUSE)

Ensure you have Free Pascal, Lazarus, and the SQLite3 shared library installed:

* **openSUSE:**

```sh
sudo zypper install lazarus sqlite3-devel libsqlite3-0
```

* **Fedora:**

```sh
sudo dnf install lazarus sqlite-devel
```

### Windows 11

* Install [Lazarus IDE](https://www.lazarus-ide.org/).  
* The repository includes `sqlite3.dll` for instant plug-and-play execution.

---

## 📦 Installation & Setup

1. **Clone the repository:**

```sh
git clone https://github.com/crazyram-uk/CD_CollectDB.git
cd CD_CollectDB
```

2. **Build with Lazarus:**

   * Open `project1.lpi` in Lazarus IDE.  
   * Press **F9** (or go to `Run` \-\> `Build`) to compile and launch.

---

## 💻 Tech Stack & Architecture

* **IDE / Language:** Lazarus & Free Pascal (FPC)  
* **Database:** SQLite3 via standard `TSQLQuery`, `TSQLTransaction`, and `TSQLite3Connection` components.  
* **XML Engine:** `TXMLDocument` for XSPF schema parsing.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
