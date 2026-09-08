# Android Bionic (proposed `lib/libc/android`)

Zig ships musl sources and glibc stubs so `-lc` works when cross-compiling
those ABIs. Android has no equivalent tree here yet.

## Options for upstream

1. **Document + resolve NDK** (smallest). Zig looks at `ANDROID_NDK_HOME`
   or a hashed fetch, writes a libc file, links. No Bionic sources in-tree.
2. **Stub `.so` like glibc** (medium). Symbol lists per API level, link
   against stubs, run against device Bionic.
3. **Ship Bionic** (largest). Only makes sense if the license and update
   cadence are acceptable to the Zig project.

This proposal recommends (1) for the next release cycle and (2) if Android
is expected to stay a documented cross target.

Bionic is Android Open Source Project code. Do not copy NDK binaries into
this tree without a license review.
