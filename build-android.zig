//! Example of how a project build.zig should look once libc-on-target exists.
//! Until then, call setLibCFile on every artifact that links libc.

const std = @import("std");

pub const AndroidOptions = struct {
    abi: []const u8 = "arm64-v8a",
    api: u32 = 29,
    libc_file: ?std.Build.LazyPath = null,
};

/// Resolve aarch64-linux-android (or sibling) and attach a libc file if given.
pub fn addAndroidShared(
    b: *std.Build,
    name: []const u8,
    root_source: std.Build.LazyPath,
    opts: AndroidOptions,
) *std.Build.Step.Compile {
    const query = parseQuery(opts.abi);
    const target = b.resolveTargetQuery(query);
    const lib = b.addLibrary(.{
        .name = name,
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = root_source,
            .target = target,
            .optimize = b.standardOptimizeOption(.{}),
            .link_libc = true,
            .pic = true,
        }),
    });
    if (opts.libc_file) |f| lib.setLibCFile(f);
    return lib;
}

fn parseQuery(abi: []const u8) std.Target.Query {
    if (std.mem.eql(u8, abi, "armeabi-v7a")) {
        return .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .androideabi };
    }
    if (std.mem.eql(u8, abi, "x86_64")) {
        return .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .android };
    }
    if (std.mem.eql(u8, abi, "x86")) {
        return .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .android };
    }
    return .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .android };
}
