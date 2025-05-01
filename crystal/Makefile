build:
	crystal build src/crystal.cr --release

build-static:
	crystal build src/crystal.cr --release --static

build-macos:
	crystal build src/crystal.cr --release --link-flags "-L/opt/homebrew/lib"

run: build
	./crystal