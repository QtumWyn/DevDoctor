const std = @import("std");
const command = @import("command.zig");
const directory = @import("directory.zig");
const port = @import("port.zig");
const types = @import("types.zig");

const CheckSpec = types.CheckSpec;

pub const Config = struct {
    specs: []const CheckSpec,
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
