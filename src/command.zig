const std = @import("std");
const types = @import("types.zig");

const CheckResult = types.CheckResult;

pub const Spec = struct {
    name: []const u8,
    version_argument: []const u8,
};

const CommandOutcome = enum {
    passed,
    not_found,
    probe_failed,
};

pub fn check(
    io: std.Io,
    spec: Spec,
) CheckResult {
    const outcome = probeCommand(io, spec.name, spec.version_argument);

    return makeCommandResult(spec.name, outcome);
}

fn probeCommand(
    io: std.Io,
    name: []const u8,
    version_argument: []const u8,
) CommandOutcome {
    const argv = [_][]const u8{
        name,
        version_argument,
    };

    var command = std.process.spawn(io, .{
        .argv = &argv,
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
    }) catch |err| {
        return switch (err) {
            error.FileNotFound => .not_found,
            else => .probe_failed,
        };
    };

    const term = command.wait(io) catch return .probe_failed;

    return switch (term) {
        .exited => |exit_code| if (exit_code == 0)
            .passed
        else
            .probe_failed,
        else => .probe_failed,
    };
}

fn makeCommandResult(name: []const u8, outcome: CommandOutcome) CheckResult {
    return switch (outcome) {
        .passed => CheckResult{
            .category = .command,
            .name = name,
            .status = .ok,
            .detail = "Command probe passed.",
        },
        .not_found => CheckResult{
            .category = .command,
            .name = name,
            .status = .fail,
            .detail = "Command not found.",
        },
        .probe_failed => CheckResult{
            .category = .command,
            .name = name,
            .status = .fail,
            .detail = "Command probe failed.",
        },
    };
}


// =================================================
// Tests
// =================================================


test "found command passes" {
    const result = makeCommandResult("Test Command", .passed);

    try std.testing.expectEqual(
        types.Status.ok,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Command probe passed.",
        result.detail,
    );
}

test "failed command probe produces failure" {
    const result = makeCommandResult(
        "Test Command",
        .probe_failed,
    );

    try std.testing.expectEqual(
        types.Status.fail,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Command probe failed.",
        result.detail,
    );
}

test "not found command fails" {
    const result = makeCommandResult("Test Command", .not_found);

    try std.testing.expectEqual(
        types.Status.fail,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Command not found.",
        result.detail,
    );
}
