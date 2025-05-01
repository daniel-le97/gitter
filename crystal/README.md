# crystal

TODO: Write a description here

## Installation

check https://crystal-lang.org/install/ for more info

## vscode extension

Crystal Language - Crystal Language Tools

to use this you will need to install crystalline
more info can be found here
https://github.com/elbywan/crystalline

## build the application

```bash
crystal build src/crystal.cr --release
```

for static compilation

```bash
crystal build src/crystal.cr --release --static
```

for static compilation on macos

```bash
crystal build src/crystal.cr --release --link-flags "-L/opt/homebrew/lib"
```

## run the application

```bash
./crystal
```
