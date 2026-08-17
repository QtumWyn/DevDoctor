const std = @import("std");
const command = @import("command.zig");
const directory = @import("directory.zig");
const port = @import("port.zig");

pub const Config = struct {
    commands: []const command.Spec,
    directories: []const directory.Spec,
    ports: []const port.Spec,
};

pub fn parse(
    allocator: std.mem.Allocator,
    json_text: []const u8,
) !std.json.Parsed(Config) {
    return std.json.parseFromSlice(
        Config,
        allocator,
        json_text,
        .{},
    );
}
