# Running the Go Implementation

This program scans the filesystem for Git repositories and displays their paths, remote URLs, and ownership status.

## Steps to Run

1. Open a terminal and navigate to the `go` directory:
   ```bash
   cd go
   ```

2. Build the program using the Go toolchain:
   ```bash
   go build -o gitter main.go
   ```

3. Run the compiled program:
   ```bash
   ./gitter
   ```

The program will scan the home directory by default. You can modify the directory to scan by editing the `getDirectory` function in `main.go`.