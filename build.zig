const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const serialize = b.addStaticLibrary(.{
        .name = "con-serialize",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    serialize.addIncludePath(b.path("src"));
    b.installArtifact(serialize);

    const fls: []const []const u8 = &.{ "serialize.c", "writer.c" };
    serialize.addCSourceFiles(.{
        .root = b.path("src/serialize"),
        .files = fls,
    });
    serialize.installHeader(b.path("src/con_error.h"), "con_error.h");
    serialize.installHeader(b.path("src/serialize/serialize.h"), "con_serialize.h");
    serialize.installHeader(b.path("src/serialize/writer.h"), "con_serialize_writer.h");

    const con = b.addModule("con", .{
        .root_source_file = b.path("src/con.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    con.addIncludePath(b.path("src/serialize"));
    con.linkLibrary(serialize);

    const serialize_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/con.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    serialize_unit_tests.addIncludePath(b.path("src/serialize"));
    serialize_unit_tests.linkLibrary(serialize);

    const run_serialize_unit_tests = b.addRunArtifact(serialize_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_serialize_unit_tests.step);
}
