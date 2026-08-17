const std = @import("std");
const types = @import("types.zig");

const CheckResult = types.CheckResult;

pub const Spec = struct {
    path: []const u8,
};

pub fn check(io: std.Io, spec: Spec) CheckResult {
    const available = directoryAvailable(io, spec.path);

    return makeDirectoryResult(spec.path, available);
}

fn directoryAvailable(
    io: std.Io,
    path: []const u8,
) bool {
    var directory =
        std.Io.Dir.cwd().openDir(io, path, .{}) catch return false;

    defer directory.close(io);

    return true;
}

fn makeDirectoryResult(
    path: []const u8,
    available: bool,
) CheckResult {
    if (available) {
        return CheckResult{ .category = .directory, .name = path, .status = .ok, .detail = "Directory found." };
    }

    return CheckResult{ .category = .directory, .name = path, .status = .fail, .detail = "Directory not found." };
}


test "found directory passes" {
    const result = makeDirectoryResult("Test Directory", true);

    try std.testing.expectEqual(
        types.Status.ok,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Directory found.",
        result.detail,
    );
}

test "not found directory fails" {
    const result = makeDirectoryResult("Test Directory", false);

    try std.testing.expectEqual(
        types.Status.fail,
        result.status,
    );

    try std.testing.expectEqualStrings(
        "Directory not found.",
        result.detail,
    );
}