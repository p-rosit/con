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

    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
}
