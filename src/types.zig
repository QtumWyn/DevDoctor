// ==========================================
// Types
// ==========================================

pub const Status = enum {
    ok,
    fail,
};

pub const Category = enum {
    command,
    directory,
    port,
};

pub const CheckResult = struct {
    category: Category,
    name: []const u8,
    status: Status,
    detail: []const u8,
};

pub const Summary = struct {
    total: usize,
    passed: usize,
    failed: usize,
};

pub const Report = struct {
    schema_version: u8,
    checks: []const CheckResult,
    summary: Summary,
};
