# CD Collection Manager

A portable, lightweight CD collection manager built with Lazarus and Free Pascal (FPC) using an embedded SQLite database.

## Features
- **Portable Architecture:** Run anywhere without absolute path dependencies or local configuration setups.
- **SQLite Database:** Dynamic runtime database initialization (`cd_collection.db`).
- **XSPF Playlist Import:** Native DOM-based parsing to import playlist data seamlessly.
- **Clean Codebase:** Zero compiler warnings/errors with clean separation of source files.

## Prerequisites
- [Lazarus IDE](https://www.lazarus-ide.org/) (with FPC)
- SQLite3 runtime libraries installed on your OS

## Getting Started
### Linux / macOS
1. Clone the repository:
   ```bash
   git clone [https://github.com/crazyram-uk/CD_CollectDB.git](https://github.com/crazyram-uk/CD_CollectDB.git)
1. Open project1.lpi in Lazarus IDE.
2. Build (Shift + F9) and Run (F9).

### Windows
1. Clone the repository:
DOS
   git clone [https://github.com/crazyram-uk/CD_CollectDB.git](https://github.com/crazyram-uk/CD_CollectDB.git)
   cd CD_CollectDB
3. Open project1.lpi in Lazarus for Windows.
4. Build (Shift + F9) to generate project1.exe.
4.Important (SQLite Driver): Windows does not ship with sqlite3.dll pre-installed. Download the 64-bit sqlite3.dll from the official SQLite Download Page and place it directly into the directory containing project1.exe.
5. Run project1.exe.
