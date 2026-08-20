const std = @import("std");
const command = @import("command.zig");
const directory = @import("directory.zig");
const port = @import("port.zig");


const CommandSpec = command.Spec;
const DirectorySpec = directory.Spec;
const PortSpec = port.Spec;

// ==========================================
// Types
// ==========================================

pub const Status = enum {
    ok,
    fail,
};

pub const Category = enum {
    command,
    directory,
    port,
};

pub const CheckSpec = union(enum) {
    command: CommandSpec,
    directory: DirectorySpec,
    port: PortSpec,
};

pub const CheckResult = struct {
    category: Category,
    name: []const u8,
    status: Status,
    detail: []const u8,
};

pub const Summary = struct {
    total: usize,
    passed: usize,
    failed: usize,
};

pub const Report = struct {
    schema_version: u8,
    checks: []const CheckResult,
    summary: Summary,
};


// =================================================
// Tests
// =================================================

test "CheckSpec works as intended" {
    const checkTest = CheckSpec{
        .command = .{ .name = "zig", .version_argument = "version", }
    };

    switch (checkTest) {
        .command => |spec| {
            try std.testing.expectEqualStrings(
                "zig",
                spec.name,
            );
        },
        .directory => unreachable,
        .port => unreachable,
    }
}

test "CheckSpec list can contain mixed check types" {
    const config = [_]CheckSpec{
        .{
            .command = .{
                .name = "zig",
                .version_argument = "version",
            },
        },
        .{
            .directory = .{
                .path = ".",
            },
        },
        .{
            .port = .{
                .name = "PostgreSQL",
                .port = 5432,
                .expected = .listening,
            },
        },
    };

    for (config) |check| {
        switch (check) {
            .command => |cmd| {
                try std.testing.expectEqualStrings(
                    "zig",
                    cmd.name,
                );
            },
            .directory => |dir| {
                try std.testing.expectEqualStrings(
                    ".",
                    dir.path,
                );
            },
            .port => |prt| {
                try std.testing.expectEqualStrings(
                    "PostgreSQL",
                    prt.name,
                );
            },
        }
    }
}