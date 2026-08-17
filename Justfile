run:
    zig run src/main.zig

json:
    zig run src/main.zig -- --json

test:
    zig test src/tests.zig

fmt:
    zig fmt src