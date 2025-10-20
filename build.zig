const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zdt = b.dependency("zdt", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("zlog", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "zdt", .module = zdt.module("zdt") },
        },
    });

    const lib = b.addLibrary(.{
        .name = "zlog",
        .root_module = mod,
    });
    b.installArtifact(lib);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    const check_step = b.step("check", "run syntax check");
    check_step.dependOn(&lib.step);
}
