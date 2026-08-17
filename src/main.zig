const std = @import("std");
const types = @import("types.zig");
const command = @import("command.zig");
const directory = @import("directory.zig");

const Status = types.Status;
const Category = types.Category;
const CheckResult = types.CheckResult;
const Report = types.Report;

// ==========================================
// Helpers
// ==========================================

fn announceCheck(name: []const u8) void {
    std.debug.print("Checking \"{s}\"...\n", .{name});
}

fn statusLabel(status: Status) []const u8 {
    return switch (status) {
        .ok => "OK",
        .fail => "FAIL",
    };
}

fn categoryLabel(category: Category) []const u8 {
    return switch (category) {
        .command => "Command",
        .directory => "Directory",
        .port => "Port",
    };
}

fn hasArgument(
    args: []const []const u8,
    wanted: []const u8,
) bool {
    for (args[1..]) |argument| {
        if (std.mem.eql(u8, argument, wanted)) {
            return true;
        }
    }

    return false;
}

// ==========================================
// Outputs
// ==========================================

fn printResult(result: CheckResult) void {
    std.debug.print(
        "{s} | {s} | {s} | {s}\n",
        .{
            categoryLabel(result.category),
            result.name,
            statusLabel(result.status),
            result.detail,
        },
    );
}

fn printJsonReport(
    io: std.Io,
    allocator: std.mem.Allocator,
    report: Report,
) !void {
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    var stringifier: std.json.Stringify = .{
        .writer = &output.writer,
        .options = .{
            .whitespace = .indent_2,
        },
    };

    try stringifier.write(report);

    try std.Io.File.stdout().writeStreamingAll(io, output.written());
    try std.Io.File.stdout().writeStreamingAll(io, "\n");
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    const json_mode = hasArgument(args, "--json");

    var failure_count: usize = 0;

    const cmds = [_]command.Spec{
        .{ .name = "git", .version_argument = "--version" },
        .{ .name = "def-not-a-command", .version_argument = "--version" },
    };

    const directories = [_]directory.Spec{
        .{ .path = "." },
        .{ .path = "src" },
        .{ .path = "def-not-a-directory" },
    };

    var results: [cmds.len + directories.len]CheckResult = undefined;

    for (cmds, 0..) |cmd, index| {
        if (!json_mode) {
            announceCheck(cmd.name);
        }

        results[index] = command.check(io, cmd);
    }

    for (directories, 0..) |dir, index| {
        if (!json_mode) {
            announceCheck(dir.path);
        }

        results[cmds.len + index] =
            directory.check(io, dir);
    }

    for (results) |result| {
        if (!json_mode) {
            printResult(result);
        }

        if (result.status == .fail) {
            failure_count += 1;
        }
    }
    if (!json_mode) {
        if (failure_count > 0) {
            if (failure_count == 1) {
                std.debug.print("1 diagnostic check failed.\n", .{});
            } else {
                std.debug.print(
                    "{d} diagnostic checks failed.\n",
                    .{failure_count},
                );
            }
        }
    }

    const report = Report{
        .schema_version = 1,
        .checks = results[0..],
        .summary = .{
            .total = results.len,
            .passed = results.len - failure_count,
            .failed = failure_count,
        },
    };

    if (json_mode) {
        try printJsonReport(io, init.gpa, report);
    }
}
