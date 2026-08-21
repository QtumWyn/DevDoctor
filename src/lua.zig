const std = @import("std");
const L = @import("lua");
const types = @import("types.zig");

const CheckSpec = types.CheckSpec;

const LuaNumber = union(enum) {
    integer: L.lua_Integer,
    float: L.lua_Number,
};

fn readRequiredString(
    allocator: std.mem.Allocator,
    state: *L.lua_State,
    field_name: [*:0]const u8,
) ![]u8 {
    _ = L.lua_getfield(
        state,
        -1,
        field_name,
    );

    if (L.lua_type(state, -1) != L.LUA_TSTRING) {
        L.lua_pop(state, 1);
        return error.ExpectedString;
    }

    var string_length: usize = 0;

    const string_ptr = L.lua_tolstring(
        state,
        -1,
        &string_length,
    ) orelse {
        L.lua_pop(state, 1);
        return error.ExpectedString;
    };

    const borrowed = string_ptr[0..string_length];
    const owned = try allocator.dupe(
        u8,
        borrowed,
    );
    L.lua_pop(state, 1);

    return owned;
}

fn readRequiredBoolean() !bool {
    // TO-DO: Write Boolean Acceptance Function
}

fn readRequiredNumber() !LuaNumber {
    // TO-DO: Write Integer/Float Acceptance Function
}

// Test Lua Integration
pub fn testLua(allocator: std.mem.Allocator) !void {
    const state = L.luaL_newstate() orelse
        return error.LuaStateCreationFailed;

    defer L.lua_close(state);

    std.debug.print("Lua VM successfully added to Zig!\n", .{});

    L.luaL_openlibs(state);

    if (L.luaL_loadfilex(
        state,
        "lua/test.lua",
        null,
    ) != 0) {
        return error.LuaLoadFailed;
    }

    if (L.lua_pcallk(
        state,
        0,
        1,
        0,
        0,
        null,
    ) != 0) {
        return error.LuaExecutionFailed;
    }

    if (L.lua_type(state, -1) != L.LUA_TTABLE) {
        return error.ExpectedTable;
    }

    _ = L.lua_getfield(
        state,
        -1,
        "value",
    );

    var is_number: c_int = 0;

    const value = L.lua_tointegerx(
        state,
        -1,
        &is_number,
    );

    if (is_number == 0) {
        return error.ExpectedNumber;
    }

    std.debug.print(
        "Value from Lua: {d}\n",
        .{value},
    );

    L.lua_pop(state, 1);

    _ = L.lua_getfield(
        state,
        -1,
        "name",
    );

    if (L.lua_type(state, -1) != L.LUA_TSTRING) {
        return error.ExpectedString;
    }

    var string_length: usize = 0;

    const string_ptr = L.lua_tolstring(
        state,
        -1,
        &string_length,
    );

    if (string_ptr == null) {
        return error.ExpectedString;
    }

    const borrowed_name =
        string_ptr[0..string_length];

    const owned_name = try allocator.dupe(
        u8,
        borrowed_name,
    );
    defer allocator.free(owned_name);

    L.lua_pop(state, 1);

    std.debug.print(
        "Name from Lua: {s}\n",
        .{owned_name},
    );
}


pub fn loadCommand(allocator: std.mem.Allocator) !CheckSpec {
    const state = L.luaL_newstate() orelse
        return error.LuaStateCreationFailed;

    defer L.lua_close(state);

    L.luaL_openlibs(state);
    if (L.luaL_loadfilex(
        state,
        "lua/checkspec.lua",
        null,
    ) != 0) {
        return error.LuaLoadFailed;
    }

    if (L.lua_pcallk(
        state,
        0,
        1,
        0,
        0,
        null,
    ) != 0) {
        return error.LuaExecutionFailed;
    }
    if (L.lua_type(state, -1) != L.LUA_TTABLE) {
        return error.ExpectedTable;
    }

    _ = L.lua_getfield(
        state,
        -1,
        "version_argument",
    );

    if (L.lua_type(state, -1) != L.LUA_TSTRING) {
        return error.ExpectedString;
    }

    var string_length: usize = 0;

    const string_ptr = L.lua_tolstring(
        state,
        -1,
        &string_length,
    );

    if (string_ptr == null) {
        return error.ExpectString;
    }

    const borrowed_version_arg = string_ptr[0..string_length];
    const owned_version_arg = try allocator.dupe(
        u8,
        borrowed_version_arg,
    );
    defer allocator.free(owned_version_arg);
    L.lua_pop(state, 1);
}