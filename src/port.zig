const std = @import("std");
const types = @import("types.zig");

const CheckResult = types.CheckResult;

pub const ExpectedState = enum {
    free,
    listening,
};

pub const Spec = struct {
    name: []const u8,
    port: u16,
    expected: ExpectedState,
};

pub fn check(
    io: std.Io,
    spec: Spec,
) CheckResult {
    const is_listening = isListening(io, spec.port);

    return makePortResult(spec.name, spec.expected, is_listening);
}

fn isListening(
    io: std.Io,
    port_number: u16,
) bool {
    var address: std.Io.net.IpAddress = .{
        .ip4 = .loopback(port_number),
    };

    var stream = address.connect(io, .{
        .mode = .stream,
    }) catch return false;

    defer stream.close(io);

    return true;
}

fn makePortResult(
    name: []const u8,
    expected: ExpectedState,
    listening: bool,
) CheckResult {
    if (listening) {
        return switch (expected) {
            .listening => CheckResult{ .category = .port, .name = name, .status = .ok, .detail = "Port is listening." },
            .free => CheckResult{
                .category = .port,
                .name = name,
                .status = .fail,
                .detail = "Port is listening.",
            },
        };
    }

    return switch (expected) {
        .listening => CheckResult{
            .category = .port,
            .name = name,
            .status = .fail,
            .detail = "Port is free.",
        },
        .free => CheckResult{
            .category = .port,
            .name = name,
            .status = .ok,
            .detail = "Port is free.",
        },
    };
}




test "listening port fails when free was expected" {
    const result = makePortResult("Test port", .free, true);

    try std.testing.expectEqual(
        types.Status.fail,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Port is listening.",
        result.detail,
    );
}

test "listening port passes when listening was expected" {
    const result = makePortResult("Test port", .listening, true);

    try std.testing.expectEqual(
        types.Status.ok,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Port is listening.",
        result.detail,
    );
}

test "free port fails when listening was expected" {
    const result = makePortResult("Test port", .listening, false);

    try std.testing.expectEqual(
        types.Status.fail,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Port is free.",
        result.detail,
    );
}

test "free port passes when free was expected" {
    const result = makePortResult("Test port", .free, false);

    try std.testing.expectEqual(
        types.Status.ok,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Port is free.",
        result.detail,
    );
}