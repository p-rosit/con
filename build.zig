const std = @import("std");

pub fn build(b: *std.Build) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gci = b.dependency("gci", .{
        .target = target,
        .optimize = optimize,
    });

    const utils = b.addStaticLibrary(.{
        .name = "con-utils",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    utils.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{"utils.c"},
    });

    const serialize = buildCLib(b, allocator, .{
        .target = target,
        .optimize = optimize,
        .name = "con-serialize",
        .root = "src/serialize",
        .sources = &.{ "serialize.c", "writer.c" },
        .headers = &.{ "con_serialize.h", "con_writer.h" },
    });
    serialize.linkLibrary(utils);
    serialize.addIncludePath(gci.path("src/interface"));
    serialize.installHeader(b.path("src/con_common.h"), "con_common.h");

    const deserialize = buildCLib(b, allocator, .{
        .target = target,
        .optimize = optimize,
        .name = "con-deserialize",
        .root = "src/deserialize",
        .sources = &.{ "deserialize.c", "reader.c" },
        .headers = &.{ "con_deserialize.h", "con_reader.h" },
    });
    serialize.linkLibrary(utils);
    deserialize.addIncludePath(gci.path("src/interface"));
    deserialize.installHeader(b.path("src/con_common.h"), "con_common.h");

    const con = b.addModule("con", .{
        .root_source_file = b.path("src/con.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "gci", .module = gci.module("gci") }},
        .link_libc = true,
    });
    con.addIncludePath(b.path("src"));
    con.addIncludePath(gci.path("src"));
    con.addIncludePath(gci.path("src/interface"));
    con.addIncludePath(gci.path("src/implementation"));
    con.linkLibrary(serialize);
    con.linkLibrary(deserialize);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/con.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    unit_tests.addIncludePath(b.path("src"));
    unit_tests.addIncludePath(b.path("src/serialize"));
    unit_tests.addIncludePath(b.path("src/deserialize"));
    unit_tests.addIncludePath(gci.path("src"));
    unit_tests.addIncludePath(gci.path("src/interface"));
    unit_tests.addIncludePath(gci.path("src/implementation"));
    unit_tests.linkLibrary(serialize);
    unit_tests.linkLibrary(deserialize);
    unit_tests.root_module.addImport("gci", gci.module("gci"));

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

const CLibConfig = struct {
    target: ?std.Build.ResolvedTarget = null,
    optimize: ?std.builtin.OptimizeMode = null,
    name: []const u8,
    root: []const u8,
    sources: []const []const u8,
    headers: ?[]const []const u8 = null,
};

fn buildCLib(b: *std.Build, allocator: std.mem.Allocator, config: CLibConfig) *std.Build.Step.Compile {
    const target = config.target orelse b.standardTargetOptions(.{});
    const optimize = config.optimize orelse b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = config.name,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("src/serialize"));
    lib.addIncludePath(b.path("src/deserialize"));
    b.installArtifact(lib);

    lib.addCSourceFiles(.{
        .root = b.path(config.root),
        .files = config.sources,
    });

    if (config.headers) |headers| {
        for (headers) |header| {
            const path = std.fs.path.join(allocator, &.{ config.root, header }) catch @panic("oom");
            defer allocator.free(path);

            lib.installHeader(b.path(path), header);
        }
    }

    return lib;
}
