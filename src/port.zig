const std = @import("std");

pub const ExpectedState = enum {
    free,
    listening,
};

pub const Spec = struct {
    name: []const u8,
    port: u16,
    expected: ExpectedState,
};

pub fn isListening(
    io: std.Io,
    port_number: u16,
) bool {
    var address: std.Io.net.IpAddress = .{
        .ip4 = .loopback(port_number),
    };

    var stream = address.connect(io, .{
        .mode = .stream,
    }) catch return false;

    defer stream.close(io);

    return true;
}