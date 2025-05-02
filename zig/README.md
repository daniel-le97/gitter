# Gitter  WIP

Gitter is a command-line tool written in Zig that helps you find Git repositories on your file system. It recursively searches directories and identifies Git repositories, optionally extracting their names from GitHub URLs.

## installing zig
To install Zig, follow the instructions on the [Zig website](https://ziglang.org/download/).

i use zvm to manage zig versions. You can install it with the following command:

```bash
curl https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash

```
this will install zig 0.14.0 and a zls (zig language server) compatible with it.
```bash
zvm install 0.14.0 --zls
```

# Running the Zig Implementation

This program scans the filesystem for Git repositories and prints their paths and remote URLs (if available).

## Steps to Run

1. Open a terminal and navigate to the `zig` directory:
   ```bash
   cd zig
   ```

2. Build the program using the Zig build system:
   ```bash
   zig build
   ```

3. Run the compiled program:
   ```bash
   zig-out/bin/cli
   ```

The program will scan the home directory by default. You can modify the directory to scan by editing the source code in `src/main.zig`.
