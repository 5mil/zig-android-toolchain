# Proposed Zig Android toolchain

These files are a **toolchain proposal** for [ziglang/zig](https://codeberg.org/ziglang/zig).
They do not change the Zig language. They describe how the compiler and
build system should treat `*-linux-android` the same way they treat
`*-linux-gnu` and `*-linux-musl`: one target, one libc file, no hand-written
include paths in every project.

Zig already accepts Android triples and stores an API level on
`std.Target` (default 29). What is still missing is Bionic at link time
and a libc file that is applied to the whole dependency graph.

## Intended upstream paths

| This repo | Suggested location in ziglang/zig |
|---|---|
| `doc/android.md` | `doc/android.md` or a section of platform-support |
| `lib/libc/android/README.md` | `lib/libc/android/README.md` |
| `lib/libc/android/triples.txt` | reference next to other libc notes |
| `tools/gen-android-libc.zig` | `tools/` or `lib/std/zig/` helper |
| `build-android.zig` | pattern for `std.Build` once libc-file-on-target lands |

Do not open this as an LLM-authored issue on the Zig tracker. Copy the
proposal into your own words if you file it on Codeberg.

## What Zig already has

- Triples: `aarch64-linux-android`, `arm-linux-androideabi`,
  `x86_64-linux-android`, `i686-linux-android`
- API level on `std.Target` (default 29; levels below 29 require libc
  because of emulated TLS)
- `zig libc` / `--libc` file format

## What is still missing

1. A Bionic sysroot Zig can use when cross-compiling, either bundled or
   fetched and hashed like other toolchain pieces.
2. Separate `crt_dir` (API-level objects: `crtbegin_so.o`) and `gcc_dir` /
   library dir (where `libc.so` lives one level up in the NDK layout).
3. Applying one libc file to every artifact in a `zig build` graph so
   dependencies do not each need `setLibCFile`.
4. CI that builds `-target aarch64-linux-android -lc`.

## Local use until that lands

```bash
export ANDROID_NDK_HOME=/path/to/ndk
zig run tools/gen-android-libc.zig -- --abi arm64-v8a --api 29 > libc-android-29-arm64.txt
zig build-exe -target aarch64-linux-android -lc --libc libc-android-29-arm64.txt src/main.zig
```
