//! Generate a Zig libc.txt for an Android NDK sysroot.
//!
//!   zig run tools/gen-android-libc.zig -- --abi arm64-v8a --api 29
//!
//! Reads ANDROID_NDK_HOME or ANDROID_HOME/ndk/<newest>.
//! Prints libc.txt on stdout.

const std = @import("std");

const Abi = enum {
    arm64_v8a,
    armeabi_v7a,
    x86_64,
    x86,

    fn ndkTriple(self: Abi) []const u8 {
        return switch (self) {
            .arm64_v8a => "aarch64-linux-android",
            .armeabi_v7a => "arm-linux-androideabi",
            .x86_64 => "x86_64-linux-android",
            .x86 => "i686-linux-android",
        };
    }

    fn parse(s: []const u8) ?Abi {
        if (std.mem.eql(u8, s, "arm64-v8a") or std.mem.eql(u8, s, "aarch64")) return .arm64_v8a;
        if (std.mem.eql(u8, s, "armeabi-v7a") or std.mem.eql(u8, s, "arm")) return .armeabi_v7a;
        if (std.mem.eql(u8, s, "x86_64")) return .x86_64;
        if (std.mem.eql(u8, s, "x86") or std.mem.eql(u8, s, "i686")) return .x86;
        return null;
    }
};

fn findNdk(arena: std.mem.Allocator) ![]const u8 {
    if (std.posix.getenv("ANDROID_NDK_HOME")) |p| return p;
    if (std.posix.getenv("NDK_ROOT")) |p| return p;
    if (std.posix.getenv("ANDROID_HOME")) |home| {
        const ndk_root = try std.fs.path.join(arena, &.{ home, "ndk" });
        var dir = std.fs.cwd().openDir(ndk_root, .{ .iterate = true }) catch return error.NoNdk;
        defer dir.close();
        var it = dir.iterate();
        var best: ?[]const u8 = null;
        while (try it.next()) |ent| {
            if (ent.kind != .directory) continue;
            if (best == null or std.mem.order(u8, ent.name, best.?) == .gt) {
                best = try arena.dupe(u8, ent.name);
            }
        }
        if (best) |name| return try std.fs.path.join(arena, &.{ ndk_root, name });
    }
    return error.NoNdk;
}

fn hostPrebuilt(ndk: []const u8, arena: std.mem.Allocator) ![]const u8 {
    const base = try std.fs.path.join(arena, &.{ ndk, "toolchains", "llvm", "prebuilt" });
    const names = [_][]const u8{
        "linux-x86_64",
        "linux-aarch64",
        "darwin-x86_64",
        "darwin-aarch64",
        "windows-x86_64",
    };
    for (names) |n| {
        const p = try std.fs.path.join(arena, &.{ base, n });
        std.fs.cwd().access(p, .{}) catch continue;
        return p;
    }
    return error.NoPrebuilt;
}

pub fn main() !void {
    var gpa_state: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var abi: Abi = .arm64_v8a;
    var api: u32 = 29;

    var args = try std.process.argsWithAllocator(arena);
    defer args.deinit();
    _ = args.next();
    while (args.next()) |a| {
        if (std.mem.eql(u8, a, "--abi")) {
            const v = args.next() orelse return error.MissingAbi;
            abi = Abi.parse(v) orelse return error.BadAbi;
        } else if (std.mem.eql(u8, a, "--api")) {
            const v = args.next() orelse return error.MissingApi;
            api = try std.fmt.parseInt(u32, v, 10);
        } else if (std.mem.eql(u8, a, "--help")) {
            const out = std.io.getStdOut().writer();
            try out.writeAll(
                "gen-android-libc --abi arm64-v8a|armeabi-v7a|x86_64|x86 --api 29\n" ++
                    "Writes a Zig libc.txt for the NDK on stdout.\n",
            );
            return;
        }
    }

    const ndk = findNdk(arena) catch {
        std.debug.print("set ANDROID_NDK_HOME or ANDROID_HOME\n", .{});
        return error.NoNdk;
    };
    const pre = try hostPrebuilt(ndk, arena);
    const sysroot = try std.fs.path.join(arena, &.{ pre, "sysroot" });
    const triple = abi.ndkTriple();
    const api_s = try std.fmt.allocPrint(arena, "{d}", .{api});

    const include_dir = try std.fs.path.join(arena, &.{ sysroot, "usr", "include" });
    const sys_include_dir = try std.fs.path.join(arena, &.{ sysroot, "usr", "include", triple });
    const crt_dir = try std.fs.path.join(arena, &.{ sysroot, "usr", "lib", triple, api_s });
    const sys_lib_dir = try std.fs.path.join(arena, &.{ sysroot, "usr", "lib", triple });

    const out = std.io.getStdOut().writer();
    try out.print(
        \\# Generated for {s} API {d}
        \\include_dir={s}
        \\sys_include_dir={s}
        \\crt_dir={s}
        \\sys_lib_dir={s}
        \\gcc_dir=
        \\msvc_lib_dir=
        \\kernel32_lib_dir=
        \\
    , .{ triple, api, include_dir, sys_include_dir, crt_dir, sys_lib_dir });
}
