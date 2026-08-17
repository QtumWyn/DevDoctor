run:
    zig build run

json:
    zig build run -- --json

test:
    zig build test --summary all

fmt:
    zig fmt build.zig src

build:
    zig build