const std = @import("std");
const types = @import("types.zig");

const CheckResult = types.CheckResult;

pub const Spec = struct {
    path: []const u8,
};

pub fn check(io: std.Io, spec: Spec) types.CheckResult {
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
