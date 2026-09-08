# How this relates to ziglang/zig

Live Zig development is on Codeberg:
https://codeberg.org/ziglang/zig

This repository is **not** a fork of the compiler. It is the toolchain
notes and generators that would accompany an Android libc story.

Suggested Codeberg issue title (post yourself; do not paste as an LLM issue):

Official Android toolchain target: Bionic + link without per-project NDK flags

Related existing work in Zig history:

- Android NDK libc.txt linking (2019)
- `std.Target` Android API level
- API default 24 → 29
- libc required for API < 29 (emulated TLS)
- libc.txt does not apply to the whole build graph
- crt_dir vs library dir mismatch on NDK layouts

Please treat this tree as review material, not as a drop-in merge.
