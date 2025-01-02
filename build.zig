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

    b.installArtifact(serialize);

    const fls: []const []const u8 = &.{"serialize.c"};
    serialize.addCSourceFiles(.{
        .root = b.path("src/serialize"),
        .files = fls,
    });
    serialize.installHeader(
        b.path("src/serialize/serialize.h"),
        "serialize.h",
    );

    const deserialize = b.addStaticLibrary(.{
        .name = "con-deserialize",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    b.installArtifact(deserialize);

    const dls: []const []const u8 = &.{"deserialize.c"};
    deserialize.addCSourceFiles(.{
        .root = b.path("src/deserialize"),
        .files = dls,
    });
    deserialize.installHeader(
        b.path("src/deserialize/deserialize.h"),
        "deserialize.h",
    );

    const serialize_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/serialize/serialize.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    serialize_unit_tests.addIncludePath(b.path("src/serialize"));
    serialize_unit_tests.linkLibrary(serialize);

    const run_lib_unit_tests = b.addRunArtifact(serialize_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
