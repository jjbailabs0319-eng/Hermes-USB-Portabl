# Portable OpenClaw

Portable OpenClaw workspace for Windows, Linux, and macOS.

Users normally only need:

```text
run.bat   Windows
run.sh    Linux or macOS
```

The launcher downloads portable Node.js and installs OpenClaw inside this folder. It does not require system Node.js, system npm, or a global OpenClaw install.

## What Is Shared

Chats, sessions, memory, credentials, model setup, channel setup, workspace files, and OpenClaw state are stored under `data/` and travel with the drive.

Each OS still gets its own runtime and package folder because Windows, Linux, and macOS binaries are different.

Generated folders are ignored by Git:

```text
runtime/
packages/
logs/
data/config/
data/openclaw/
data/home/
data/workspace/
data/temp/
```

## First Run

Windows:

```text
run.bat
```

Linux/macOS:

```bash
sh run.sh
```

First run on each OS needs internet to download that OS runtime and install OpenClaw. After that, the same OS reuses its portable runtime from the drive.

## Menu

```text
Portable OpenClaw

1. Setup / Change AI
2. Chat
3. Dashboard
4. Tools
5. Run OpenClaw Command
0. Exit
```

Use `Setup / Change AI` first, then use `Chat` or `Dashboard` for normal work.
Use `Run OpenClaw Command` when OpenClaw tells you to run a direct command, for example `openclaw pairing approve telegram R2F8ZL5S`.
