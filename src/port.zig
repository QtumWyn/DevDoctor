pub const ExpectedState = enum {
    free,
    listening,
};

pub const Spec = struct {
    name: []const u8,
    port: u16,
    expected: ExpectedState,
};