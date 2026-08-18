const std = @import("std");
const Report = @import("types.zig").Report;
const helpers = @import("helpers.zig");
const config_module = @import("config.zig");
const runner = @import("runner.zig");
const reporting = @import("reporting.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    const json_mode = helpers.hasArgument(args, "--json");

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

    const progress: ?runner.ProgressFn =
        if (json_mode)
            null
        else
            &reporting.printProgress;

    const results = try runner.run(
        init.gpa,
        io,
        config,
        progress,
    );
    defer init.gpa.free(results);

    const summary = runner.summarize(results);

    for (results) |result| {
        if (!json_mode) {
            reporting.printResult(result);
        }
    }

    if (!json_mode) {
        reporting.printSummary(summary);
    }

    const report = Report{
        .schema_version = 1,
        .checks = results,
        .summary = summary,
    };

    if (json_mode) {
        try reporting.printJsonReport(io, init.gpa, report);
    }
}
