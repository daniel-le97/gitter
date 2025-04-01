# Gitter  WIP

Gitter is a command-line tool written in Zig that helps you find Git repositories on your file system. It recursively searches directories and identifies Git repositories, optionally extracting their names from GitHub URLs.


## Features

- Recursively scans directories for `.git` folders.
- Prints the paths of Git repositories found.
- Extracts and displays repository names from GitHub URLs (if available).

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/gitter.git
   cd gitter
   ```
2. build the project:
   ```bash
   zig build
   ```
