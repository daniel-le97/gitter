# Running the C Implementation

This program scans the filesystem for Git repositories and prints their paths and remote URLs (if available).

## Steps to Run

1. Open a terminal and navigate to the `c` directory:
   ```bash
   cd c
   ```

2. Compile the program using `gcc`:
   ```bash
   gcc -o gitter gitter.c
   ```

3. Run the compiled program, providing the directory to scan as an argument:
   ```bash
   ./gitter /path/to/scan
   ```

Replace `/path/to/scan` with the directory you want to scan for Git repositories.