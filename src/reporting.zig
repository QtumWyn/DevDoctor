const std = @import("std");
const helpers = @import("helpers.zig");
const types = @import("types.zig");
const Summary = @import("types.zig").Summary;

const CheckResult = types.CheckResult;
const Report = types.Report;

pub fn printProgress(
    category: types.Category,
    name: []const u8,
) void {
    std.debug.print(
        "Checking {s} \"{s}\"...\n",
        .{
            helpers.categoryLabel(category),
            name,
        },
    );
}

pub fn printResult(result: CheckResult) void {
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

pub fn printSummary(summary: Summary) void {
    if (summary.failed > 0) {
        if (summary.failed == 1) {
            std.debug.print("1 diagnostic check failed.\n", .{});
        } else {
            std.debug.print(
                "{d} diagnostic checks failed.\n",
                .{summary.failed},
            );
        }
    }
}

pub fn printJsonReport(
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