const std = @import("std");
const types = @import("types.zig");
const command = @import("command.zig");
const directory = @import("directory.zig");
const port = @import("port.zig");
const helpers = @import("helpers.zig");
const config_module = @import("config.zig");

const CheckResult = types.CheckResult;
const Report = types.Report;

// ==========================================
// Outputs
// ==========================================

fn printResult(result: CheckResult) void {
    std.debug.print(
        "{s} | {s} | {s} | {s}\n",
        .{
            helpers.categoryLabel(result.category),
            result.name,
            helpers.statusLabel(result.status),
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

    const json_mode = helpers.hasArgument(args, "--json");

    var failure_count: usize = 0;

    const config_argument = helpers.argumentValue(
        args,
        "--config",
    ) catch |err| switch (err) {
        error.MissingValue => {
            std.debug.print(
                "devdoctor: --config requires a file path.\n",
                .{},
            );

            std.process.exit(2);
        },
    };

    const config_path =
        config_argument orelse "devdoctor.json";

    const config_text = try std.Io.Dir.cwd().readFileAlloc(
        io,
        config_path,
        init.gpa,
        .limited(1024 * 1024),
    );
    defer init.gpa.free(config_text);

    const parsed_config = try config_module.parse(
        init.gpa,
        config_text,
    );
    defer parsed_config.deinit();

    const config = parsed_config.value;

    const total_checks = config.commands.len + config.directories.len + config.ports.len;

    const results = try init.gpa.alloc(CheckResult, total_checks);

    defer init.gpa.free(results);

    for (config.commands, 0..) |cmd, index| {
        if (!json_mode) {
            helpers.announceCheck(cmd.name);
        }

        results[index] = command.check(io, cmd);
    }

    for (config.directories, 0..) |dir, index| {
        if (!json_mode) {
            helpers.announceCheck(dir.path);
        }

        results[config.commands.len + index] =
            directory.check(io, dir);
    }

    for (config.ports, 0..) |port_spec, index| {
        if (!json_mode) {
            helpers.announceCheck(port_spec.name);
        }

        results[config.commands.len + config.directories.len + index] =
            port.check(io, port_spec);
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
        .checks = results,
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
