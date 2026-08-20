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
const CheckSpec = types.CheckSpec;

pub const ProgressFn = *const fn (
    ?*anyopaque,
    Category,
    []const u8,
) void;

pub const Progress = struct {
    context: ?*anyopaque,
    callback: ProgressFn,
};

pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    config: Config,
    progress: ?Progress,
) ![]CheckResult {
    const total_checks: usize = config.specs.len;

    const results = try allocator.alloc(CheckResult, total_checks);

    for (config.specs, 0..) |spec, index| {
        switch (spec) {
            .command => |cmd| {
                if (progress) |progress_info| {
                    progress_info.callback(progress_info.context, .command, cmd.name);
                }
                results[index] = command.check(io, cmd);
            },
            .directory => |dir| {
                if (progress) |progress_info| {
                    progress_info.callback(progress_info.context, .directory, dir.path);
                }
                results[index] = directory.check(io, dir);
            },
            .port => |prt| {
                if (progress) |progress_info| {
                    progress_info.callback(progress_info.context, .port, prt.name);
                }
                results[index] = port.check(io, prt);
            }
        }
    }
    return results;
}

test "run returns all configured checks" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const config = Config{
        .specs = &.{
            .{
                .command = .{
                    .name = "zig",
                    .version_argument = "version",
                }
            },
            .{
                .directory = .{
                    .path = ".",
                }
            },
        }
    };

    const results = try run(allocator, io, config, null);

    defer allocator.free(results);

    try std.testing.expectEqual(
        @as(usize, 2),
        results.len,
    );
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

const ProgressState = struct {
    calls: usize = 0,
};

fn countProgress(
    context: ?*anyopaque,
    category: Category,
    name: []const u8,
) void {
    _ = category;
    _ = name;

    const raw_context = context orelse unreachable;

    const state: *ProgressState = @ptrCast(@alignCast(raw_context));

    state.calls += 1;
}

test "run calls progress for every configured check" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const config = Config{
        .specs = &.{
            .{
                .command = .{
                    .name = "zig",
                    .version_argument = "version",
                }
            },
            .{
                .directory = .{
                    .path = ".",
                }
            },
        }
    };

    var state = ProgressState{};

    const progress = Progress{
        .context = &state,
        .callback = &countProgress,
    };

    const results = try run(
        allocator,
        io,
        config,
        progress,
    );
    defer allocator.free(results);

    try std.testing.expectEqual(
        @as(usize, 2),
        state.calls,
    );
}