# Gitter

this is an project that holds different implementations in different languages to get a feel on how they work and their ease of use

## Current Requirements

- Recursively scans directories for `.git` folders.
- must ignore the following home directories:
    - `.` directories (ie `.vscode`)
    - `/Library`
    - `/go`
- Extracts GitHub URLs from .git/config files (if available).
- should print an elapsed time when done

## Status

WIP

## Results

- vlang: 1m3.239s for 362 repos
- go: 1m6.459097333s for 367 repos
- odin: 8.682741667s for 362 repos
- zig: 868 ms for 367 repos
