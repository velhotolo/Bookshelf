<h1 align="center">Bookshelf</h1>

<p align="center">
  A personal library app written in Lua. It runs on your own computer and opens in your browser.<br>
  Keep track of the books you want to read, are reading and have already read.
</p>

<p align="center">
  <img alt="Lua 5.5" src="https://img.shields.io/badge/Lua-5.5-2C2D72?logo=lua&logoColor=white">
  <img alt="SQLite" src="https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white">
  <img alt="Platforms: Linux and Windows" src="https://img.shields.io/badge/platforms-Linux%20%7C%20Windows-1F3B32">
  <img alt="Status: early development" src="https://img.shields.io/badge/status-early%20development-B8892B">
</p>

---

## About

Bookshelf is a desktop app built the way many modern desktop apps are: a small web server that runs only on your machine, with the interface shown in your own browser. For the person using it, the experience is simple: double-click the icon, the browser opens on your shelf, and that's it.

The goal is a program anyone can download and use without knowing what Lua, a terminal or a database is:

- **Linux:** a single AppImage
- **Windows:** a `.zip` with `Bookshelf.exe`
- **No installs:** the executable is the Lua interpreter itself, with SQLite and OpenSSL compiled in

## Status

This repository is being built step by step. Right now it contains the entry point, `app/main.lua`; the modules it loads come next.

- [x] Entry point: data folder, log file, migrations, port selection, browser launch, shutdown
- [ ] `config.lua`: production, development and test environments
- [ ] `paths.lua`: per-OS data folder and `mkdir -p`
- [ ] `server.lua`: port selection, single instance, server loop, Quit button
- [ ] `web.lua`: JSON responses, request body, query string, logging
- [ ] `db.lua`: SQLite connection and versioned migrations
- [ ] Authentication: PBKDF2 password hashing and revocable tokens
- [ ] Books API: create, read, update, delete, search, filters, sorting and summary
- [ ] Browser interface with a visual shelf
- [ ] Automated tests with busted
- [ ] Packaging: AppImage for Linux and `.zip` for Windows

## How it starts

What `app/main.lua` does, in order:

1. Finds its own folder through `debug.getinfo` and adds it to `package.path`, so the app works no matter which directory it is launched from (a double-click can start it anywhere).
2. Creates the data folder and, when logging to a file, opens the log. The log starts over once it grows past 1 MB.
3. Creates or updates the database by running pending migrations.
4. Picks a port. If the port already belongs to another running Bookshelf, it just opens the browser on it and exits.
5. Opens the browser and serves requests until someone clicks **Quit** or presses <kbd>Ctrl</kbd>+<kbd>C</kbd>.
6. If anything fails during startup, the error goes to the log, Linux users get a desktop notification, and the process exits with code 1.

## Tech stack

| Piece | Role |
|---|---|
| [Lua 5.5](https://www.lua.org/) | Language and runtime |
| [Pegasus](https://github.com/EvandroLG/pegasus.lua) | HTTP request handling |
| [LuaSocket](https://github.com/lunarmodules/luasocket) | Sockets and the server loop |
| [LuaFileSystem](https://github.com/lunarmodules/luafilesystem) | Folders and file sizes |
| [lsqlite3](http://lua.sqlite.org/) + [SQLite](https://sqlite.org/) | Storage |
| [dkjson](http://dkolf.de/dkjson-lua/) | JSON encoding and decoding |
| [luaossl](https://github.com/wahern/luaossl) | Password hashing, SHA-256 and random tokens |
| [busted](https://lunarmodules.github.io/busted/) | Tests |

## Project layout

Planned structure; only the files marked as done in [Status](#status) exist so far.

```
bookshelf/
├── app/
│   ├── main.lua       # entry point
│   ├── config.lua     # environments
│   ├── paths.lua      # per-OS data folder
│   ├── server.lua     # port, single instance, server loop
│   ├── web.lua        # HTTP helpers and logging
│   ├── db.lua         # connection and migrations
│   ├── app.lua        # routes
│   └── public/        # HTML, CSS, JavaScript and icon
├── spec/              # busted tests
└── packaging/         # launcher in C and build script
```

## Development

> These commands will work once the modules listed in [Status](#status) are in place.

On Arch Linux:

```sh
sudo pacman -S --needed lua luarocks sqlite openssl base-devel git

APP_ENV=development lua app/main.lua   # run with data in ./data
APP_ENV=test busted                    # run the test suite
```

Without `APP_ENV=development`, the app runs in production mode and uses your real data folder.

## Security design

A server running on someone's personal computer still needs care. These are the design goals:

- Listens on `127.0.0.1` only, so other machines on the network cannot reach it
- Rejects unexpected `Host` headers to block DNS rebinding attacks
- Login is required, even locally
- Passwords stored as PBKDF2-SHA256; session tokens stored only as SHA-256 hashes
- Tokens sent in a header, not a cookie, which rules out CSRF
- Strict Content Security Policy: the page loads nothing from outside the app, so it also works offline

## License

No license has been chosen yet.
