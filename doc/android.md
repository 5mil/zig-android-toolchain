# Android as a Zig target

Status: proposal. Not yet a Tier-2 libc target in the sense of
"cross-compile with `-lc` and no NDK flags."

## Command that should work

```bash
zig build-exe -target aarch64-linux-android.29.0 -lc hello.zig
zig build -Dtarget=aarch64-linux-android
```

No `--libc`, no `-I`, no `-L` in the project file.

## Triples and ABIs

| Zig target | Android ABI directory | Notes |
|---|---|---|
| `aarch64-linux-android` | `arm64-v8a` | Default device target |
| `arm-linux-androideabi` | `armeabi-v7a` | 32-bit ARM |
| `x86_64-linux-android` | `x86_64` | Emulator |
| `i686-linux-android` | `x86` | 32-bit emulator |

API level is the Android OS version range on `std.Target`, not a fourth
component of the architecture. Default 29.

## NDK sysroot layout (r27+)

```
$NDK/toolchains/llvm/prebuilt/<host>/sysroot/
  usr/include/
  usr/include/<triple>/
  usr/lib/<triple>/           # libc.so, libm.so, libdl.so
  usr/lib/<triple>/<api>/     # crtbegin_so.o, crtend_android.o, crtbegin_static.o
```

A single `crt_dir` cannot point at both. Zig currently looks for `libc.a`
in `crt_dir`. Android puts CRT objects under `<triple>/<api>` and shared
libs under `<triple>`. The libc file format needs either:

- `sys_lib_dir` distinct from `crt_dir`, or
- Android-specific lookup: libraries in `dirname(crt_dir)`.

## libc.txt fields for Android

```
include_dir=<sysroot>/usr/include
sys_include_dir=<sysroot>/usr/include/<triple>
crt_dir=<sysroot>/usr/lib/<triple>/<api>
sys_lib_dir=<sysroot>/usr/lib/<triple>
gcc_dir=
msvc_lib_dir=
kernel32_lib_dir=
```

`sys_lib_dir` is the proposed extra field. Until it exists, generate two
notes in the libc file comments and put libraries on the link line via
`-L`.

## Out of scope for the compiler

- APK packaging, `zipalign`, signing, Java sources, resources
- Gradle / Android Studio project generation

Those stay in third-party build modules. The compiler owns triple, API
level, Bionic paths, and the link.
