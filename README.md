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

- zig: 868 ms for 367 repos found
- rust: 1.30s for 296 repos found
- odin: 8.682741667s for 362 repos found
- nim 34.010355 seconds for 362 repos found
- vlang: 1m3.239s for 362 repos found
- go: 1m6.459097333s for 367 repos found


please note that i am a beginner in all of these languages and the implementations are not perfect.
