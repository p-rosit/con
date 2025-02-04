const std = @import("std");

pub fn build(b: *std.Build) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const serialize = buildCLib(b, allocator, .{
        .target = target,
        .optimize = optimize,
        .name = "con-serialize",
        .root = "src/serialize",
        .sources = &.{ "serialize.c", "writer.c" },
        .headers = &.{ "serialize.h", "writer.h" },
    });

    const deserialize = buildCLib(b, allocator, .{
        .target = target,
        .optimize = optimize,
        .name = "con-deserialize",
        .root = "src/deserialize",
        .sources = &.{"reader.c"},
        .headers = &.{"reader.h"},
    });

    const con = b.addModule("con", .{
        .root_source_file = b.path("src/con.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    con.addIncludePath(b.path("src"));
    con.linkLibrary(serialize);
    con.linkLibrary(deserialize);

    const serialize_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/con.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    serialize_unit_tests.addIncludePath(b.path("src"));
    serialize_unit_tests.addIncludePath(b.path("src/serialize"));
    serialize_unit_tests.addIncludePath(b.path("src/deserialize"));
    serialize_unit_tests.linkLibrary(serialize);
    serialize_unit_tests.linkLibrary(deserialize);

    const run_serialize_unit_tests = b.addRunArtifact(serialize_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_serialize_unit_tests.step);
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
    b.installArtifact(lib);

    lib.addCSourceFiles(.{
        .root = b.path(config.root),
        .files = config.sources,
    });

    if (config.headers) |headers| {
        const prefix = "con_";
        for (headers) |header| {
            const path = std.fs.path.join(allocator, &.{ config.root, header }) catch @panic("oom");
            const name = std.mem.join(allocator, &.{}, &.{ prefix, header }) catch @panic("oom");
            defer allocator.free(path);
            defer allocator.free(name);

            lib.installHeader(b.path(path), name);
        }
    }

    return lib;
}
