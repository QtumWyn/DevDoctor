const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "devdoctor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_exe.addArgs(args);
    }
    const run_step = b.step(
        "run",
        "Run DevDoctor",
    );
    run_step.dependOn(&run_exe.step);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step(
        "test",
        "Run DevDoctor tests",
    );
    test_step.dependOn(&run_tests.step);

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("lua/lua_api.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.addSystemIncludePath(.{
        .cwd_relative = "/usr/include/lua5.4",
    });
    const lua_module = translate_c.createModule();

    exe.root_module.addImport("lua", lua_module);
    exe.root_module.linkSystemLibrary("lua5.4", .{});

    tests.root_module.addImport("lua", lua_module);
    tests.root_module.linkSystemLibrary("lua5.4", .{});
}
