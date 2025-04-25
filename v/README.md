# Running the V Implementation

This program scans the filesystem for Git repositories and prints their paths and remote URLs (if available).

## Steps to Run

1. Open a terminal and navigate to the `v` directory:
   ```bash
   cd v
   ```

2. Build the program using the V compiler:
   ```bash
   v run src/main.v
   ```

The program will scan the home directory by default. You can modify the directory to scan by editing the `os.walk` function in `src/main.v`.