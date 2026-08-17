const std = @import("std");
const types = @import("types.zig");

const CheckResult = types.CheckResult;

pub const Spec = struct {
    name: []const u8,
    version_argument: []const u8,
};

pub fn check(
    io: std.Io,
    spec: Spec,
) CheckResult {
    const available = commandAvailable(io, spec.name, spec.version_argument);

    return makeCommandResult(spec.name, available);
}

fn commandAvailable(
    io: std.Io,
    name: []const u8,
    version_argument: []const u8,
) bool {
    const argv = [_][]const u8{
        name,
        version_argument,
    };

    var command = std.process.spawn(io, .{
        .argv = &argv,
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
    }) catch return false;

    const term = command.wait(io) catch return false;

    return switch (term) {
        .exited => |exit_code| exit_code == 0,
        else => false,
    };
}

fn makeCommandResult(name: []const u8, found: bool) CheckResult {
    if (found) {
        return CheckResult{
            .category = .command,
            .name = name,
            .status = .ok,
            .detail = "Command found.",
        };
    }

    return CheckResult{
        .category = .command,
        .name = name,
        .status = .fail,
        .detail = "Command not found.",
    };
}


test "found command passes" {
    const result = makeCommandResult("Test Command", true);

    try std.testing.expectEqual(
        types.Status.ok,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Command found.",
        result.detail,
    );
}

test "not found command fails" {
    const result = makeCommandResult("Test Command", false);

    try std.testing.expectEqual(
        types.Status.fail,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Command not found.",
        result.detail,
    );
}