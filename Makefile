
ziglang:
	cd zig && zig build -Doptimize=ReleaseSafe
	cd zig && time ./zig-out/bin/gitter

vlang:
	cd v && v src/main.v
	cd v && time ./src/main


