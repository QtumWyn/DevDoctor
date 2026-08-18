const std = @import("std");
const types = @import("types.zig");
const command = @import("command.zig");
const directory = @import("directory.zig");
const port = @import("port.zig");
const config_module = @import("config.zig");

const CheckResult = types.CheckResult;
const Config = config_module.Config;
const Summary = types.Summary;
const Category = types.Category;

pub const ProgressFn = *const fn (
    Category,
    []const u8,
) void;

pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    config: Config,
    progress: ?ProgressFn,
) ![]CheckResult {
    const total_checks: usize =
        config.commands.len + config.directories.len + config.ports.len;

    const results = try allocator.alloc(CheckResult, total_checks);

    for (config.commands, 0..) |cmd, index| {
        if (progress) |callback| {
            callback(.command, cmd.name);
        }

        results[index] = command.check(io, cmd);
    }

    for (config.directories, 0..) |dir, index| {
        if (progress) |callback| {
            callback(.directory, dir.path);
        }

        results[config.commands.len + index] = directory.check(io, dir);
    }

    for (config.ports, 0..) |port_spec, index| {
        if (progress) |callback| {
            callback(.port, port_spec.name);
        }

        results[
            config.commands.len +
            config.directories.len +
            index
        ] = port.check(io, port_spec);
    }
    return results;
}

pub fn summarize(results: []const CheckResult) Summary {
    var passed: usize = 0;
    var failed: usize = 0;

    for (results) |result| {
        switch (result.status) {
            .ok => passed += 1,
            .fail => failed += 1,
        }
    }

    return Summary{
        .total = results.len,
        .passed = passed,
        .failed = failed,
    };
}

test "run returns all configured checks" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const config = Config{
        .commands = &.{
            .{
                .name = "zig",
                .version_argument = "version",
            },
        },

        .directories = &.{
            .{
                .path = ".",
            },
        },

        .ports = &.{},
    };

    const results = try run(allocator, io, config, null);

    defer allocator.free(results);

    try std.testing.expectEqual(
        @as(usize, 2),
        results.len,
    );
}

test "summarize counts passed and failed checks" {
    const results = [_]CheckResult{
        .{
            .category = .command,
            .name = "git",
            .status = .ok,
            .detail = "Command probe passed.",
        },
        .{
            .category = .command,
            .name = "def-not-a-command",
            .status = .fail,
            .detail = "Command not found.",
        },
        .{
            .category = .directory,
            .name = "src",
            .status = .ok,
            .detail = "Directory found.",
        },
        .{
            .category = .port,
            .name = "PostgreSQL",
            .status = .ok,
            .detail = "Port is listening.",
        },
        .{
            .category = .directory,
            .name = "def-not-a-directory",
            .status = .fail,
            .detail = "Directory not found.",
        },
    };

    const summary = summarize(&results);

    try std.testing.expectEqual(
        @as(usize, 5),
        summary.total,
    );
    try std.testing.expectEqual(
        @as(usize, 3),
        summary.passed,
    );
    try std.testing.expectEqual(
        @as(usize, 2),
        summary.failed,
    );
}