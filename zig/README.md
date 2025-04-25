# Gitter  WIP

Gitter is a command-line tool written in Zig that helps you find Git repositories on your file system. It recursively searches directories and identifies Git repositories, optionally extracting their names from GitHub URLs.



# Running the Zig Implementation

This program scans the filesystem for Git repositories and prints their paths and remote URLs (if available).

## Steps to Run

1. Open a terminal and navigate to the `zig` directory:
   ```bash
   cd /home/daniel/code/zig/test/zig
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
