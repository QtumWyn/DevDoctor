const std = @import("std");

// ==========================================
// Types
// ==========================================

const Status = enum {
    ok,
    fail,
};

const Category = enum {
    command,
    directory,
};

const CheckResult = struct {
    category: Category,
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

// ==========================================
// Commands
// ==========================================

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

// ==========================================
// Directories
// ==========================================

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

    const cmds = [_]CommandSpec{
        .{ .name = "git", .version_argument = "--version" },
        .{ .name = "def-not-a-command", .version_argument = "--version" },
    };

    const directories = [_][]const u8{
        ".",
        "src",
        "def-not-a-directory",
    };

    var results: [cmds.len + directories.len]CheckResult = undefined;

    for (cmds, 0..) |cmd, index| {
        if (!json_mode) {
            announceCheck(cmd.name);
        }

        const available = commandAvailable(io, cmd.name, cmd.version_argument);

        results[index] = makeCommandResult(cmd.name, available);
    }

    for (directories, 0..) |path, index| {
        if (!json_mode) {
            announceCheck(path);
        }

        const available = directoryAvailable(io, path);

        results[cmds.len + index] =
            makeDirectoryResult(path, available);
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
