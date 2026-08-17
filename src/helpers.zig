const std = @import("std");
const types = @import("types.zig");

const Status = types.Status;
const Category = types.Category;

pub fn announceCheck(name: []const u8) void {
    std.debug.print("Checking \"{s}\"...\n", .{name});
}

pub fn statusLabel(status: Status) []const u8 {
    return switch (status) {
        .ok => "OK",
        .fail => "FAIL",
    };
}

pub fn categoryLabel(category: Category) []const u8 {
    return switch (category) {
        .command => "Command",
        .directory => "Directory",
        .port => "Port",
    };
}

pub fn hasArgument(
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
