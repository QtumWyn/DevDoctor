const std = @import("std");

const Status = enum {
    ok,
    fail,
};

const CheckResult = struct {
    category: []const u8,
    name: []const u8,
    status: Status,
    detail: []const u8,
};

const CommandSpec = struct {
    name: []const u8,
    version_argument: []const u8,
};

const Summary = struct {
    total: usize,
    passed: usize,
    failed: usize,
};

const Report = struct {
    schema_version: u8,
    checks: []const CheckResult,
    summary: Summary,
};

fn announceCommand(name: []const u8) void {
    std.debug.print("Checking {s}...\n", .{name});
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
            .category = "Command",
            .name = name,
            .status = .ok,
            .detail = "Command found.",
        };
    }

    return CheckResult{
        .category = "Command",
        .name = name,
        .status = .fail,
        .detail = "Command not found.",
    };
}

fn statusLabel(status: Status) []const u8 {
    return switch (status) {
        .ok => "OK",
        .fail => "FAIL",
    };
}

fn printResult(result: CheckResult) void {
    std.debug.print(
        "{s} | {s} | {s} | {s}\n",
        .{
            result.category,
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

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    const json_mode = hasArgument(args, "--json");

    var failure_count: usize = 0;

    const cmds = [_]CommandSpec{
        .{ .name = "git", .version_argument = "--version" },
        .{ .name = "def-not-a-command", .version_argument = "--version" },
    };

    var results: [cmds.len]CheckResult = undefined;

    for (cmds, 0..) |cmd, index| {
        if (!json_mode) {
            announceCommand(cmd.name);
        }

        const available = commandAvailable(io, cmd.name, cmd.version_argument);

        results[index] = makeCommandResult(cmd.name, available);
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
