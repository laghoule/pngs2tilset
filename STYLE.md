# STYLE — TigerStyle for pngs2tileset

This project follows [TigerStyle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
(TigerBeetle's coding style) as its baseline, adapted to what pngs2tileset is: a
small, fail-fast CLI asset tool that feeds a hand-written 8086 engine (mquest).
Where TigerStyle serves a latency-critical database, we borrow its safety and
design discipline and consciously tailor the rest. Every deviation from
TigerStyle is listed at the bottom, with its reason.

> "Style is more than readability, and readability is table stakes, a means to
> an end rather than an end in itself." — TigerStyle

## Design goals

In order:

1. **Correctness.** The `.til` output must be byte-exact and deterministic:
   same inputs, same outputs, tile ordering included. The engine trusts this
   file blindly; there is no server to report a wrong pixel.
2. **Fail-fast.** A bad input stops the run with a clear message, an error exit
   code, and no partial files left behind. A silent wrong output is the worst
   outcome; an early crash is second.
3. **Developer experience.** This tool exists so that the mquest developer
   (working in assembly) can move faster. Clear errors, clear names, no magic.
4. **Performance.** Not a goal in itself: the tool runs offline, once per
   asset change. This is the main inversion from TigerBeetle, where
   performance ranks right after safety. Conversely, the *output's* simplicity
   (raw indices, `SHL`-friendly strip layout) is a performance decision for the
   8086 engine — keep the format decisions stable.

## Rules we adopt

### Safety

- **Simple, explicit control flow. No recursion.** The input domain is known
  and bounded (files on disk); a loop is enough and easier to bound.
- **Put a limit on everything.** Maximum PNG count, maximum palette file
  size, maximum tile dimensions: every loop and buffer has a fixed upper
  bound, asserted at the boundary. Constants are named (`entry_count_max`,
  `png_count_max`) and asserted against in one place.
- **Assertions are for programmer errors; errors are for operating errors.**
  A `.gpl` with 250 entries is an operating error: report it. An index
  computed outside `0..255` is a programmer error: `assert` and crash.
  Assertions document the code's internal contract; aim for roughly two per
  meaningful function, split compound conditions (`assert(a); assert(b);`
  over `assert(a and b);`), and use single-line
  `if (condition) assert(consequence);` for implications.
- **Pair assertions across the read/write boundary.** Whatever validity is
  checked when consuming a file must be re-checked (asserted) in the layer
  that produces it, and vice versa. Saves the next reader a debugging session.
- **Compile-time assertions.** Use `comptime { ... }` blocks to assert layout
  and size relationships (`@sizeOf`, array lengths). The `.til` format is
  frozen; encode it in types where possible (`[256]Color`, not a dynamic
  list that happens to have 256 items today).
- **Explicitly sized integers.** Dimensions and counts use `u16`/`u32`;
  color maths that could overflow go to `u32` with an explicit `@intCast`
  guarded by an assert, never a silent widening/wrapping. Use `usize` only
  where the standard library API requires it, never as the domain's choice.
- **All errors are handled.** No `catch unreachable` on I/O paths in release
  builds. The CLI prints an actionable message to stderr and exits non-zero;
  partial outputs are removed (`errdefer`) — see TODO "delete partial outputs".

### Memory

- **One arena for the whole run.** The process `init` hands us an arena;
  everything allocated during a run comes from it and dies with it. No
  long-lived incremental allocations, no per-pixel allocation, no allocator
  choice left to chance mid-call-tree. Where a function needs an allocator,
  it takes the arena (or a scoped child) as a parameter — never a global.
- **Statically sized domain types.** `[256]Color` for the palette, comptime
  sizes for tile geometry. Dynamic buffers (`std.ArrayList`) only for the
  unbounded inputs: the list of PNG paths and the index buffer itself, still
  bounded by an asserted maximum.
- **In-place construction via out pointers.** Structures with domain weight
  (e.g. `Palette`) are initialized through `init(target: *Palette) !void` and
  filled in place, instead of being built and moved around. Small, immutable
  result structs may be returned by value.

### Developer experience

- **Get the nouns and verbs right.** `source`, `palette`, `destination`,
  `tile`, `entry` — the same words as the CLI flags and the format
  descriptions, consistently. No abbreviations (`destination`, not `dest`).
- **Units and qualifiers go last**, most significant first:
  `tile_width_px`, `png_count_max`, `palette_entry_count`. Related names then
  align vertically, and `png_count_max`/`png_count` stay adjacent.
- **`snake_case` for files and functions, `CamelCase` for types** (Zig's
  standard). One word per concept; do not overload a name with two meanings.
- **Order: important things first.** `main` at the top of `main.zig`; within
  a file: fields, then types, then functions. Helpers called by a function
  are prefixed with the caller's name (`remap_tile_nearest(...)`).
- **Say why, and say how.** Doc comments (`///`) on public declarations.
  Comments are prose sentences explaining the *why*, not transcripts of the
  code. Commit messages explain intent — commit history is the repo's
  changelog and `git blame` is its documentation.
- **`zig fmt` is mandatory.** 4 spaces, 100 columns hard limit, trailing
  comma to let `zig fmt` wrap multiline calls. Braces on `if` unless the
  whole statement fits on one line.
- **Functions stay under ~70 lines.** Centralize control flow: keep the
  `switch`/`if`s in the parent function, push non-branchy fragments into
  pure helpers. "Push `if`s up and `for`s down."

### Testing

- **Tests exercise the negative space.** Every parse/validate path gets a
  valid case *and* its invalid siblings: `.gpl` too short, value out of
  range, PNG dimensions mismatching, alpha neither 0 nor 255, unknown flags.
- **Unit tests only, deterministic, in-memory** where possible (TODO
  decision). No test depends on files produced by a prior test.
- **`zig build test` must stay green.** A phase is not done while red, and
  untested error paths are red by definition.

### Process

- **Zero technical debt in scope.** Do it right the first time, per phase's
  "done when". Realized-but-out-of-scope decisions go to TODO.md explicitly,
  not to hand-wavy comments.
- **Session protocol lives in TODO.md** ("How to work on this file"): one
  phase in progress at a time. STYLE.md is consulted at "Done when" time,
  not mid-flow.
- **One dependency rule.** zigimg is our only dependency (see deviations).
  Any additional dependency requires a written justification (commit message
  or TODO.md) arguing why not hand-rolling it.
- **Zig for tooling.** Scripts live in `scripts/` as `*.zig`, not `*.sh`,
  when scripts become necessary; the Dockerfile stays the environment.

## Deliberate deviations from TigerStyle

| Deviation | Reason |
| --- | --- |
| **Dependency on `zigimg`** (TigerStyle: zero dependencies) | PNG decoding is a large, error-prone specification; a hand-rolled decoder would carry more risk than the dependency. The supply-chain surface stays at exactly one reviewed dependency, fetched as a build dependency. |
| **Arena-during-run instead of fully static startup memory** (TigerStyle: all memory static after init) | For a batch CLI, the process-lifetime arena gives the same safety property (no incremental lifetime reasoning, no per-item frees) without precomputing worst-case budgets for every data structure. |
| **Performance treated as a non-goal** (TigerStyle: optimize early for 1000x wins) | The tool runs offline and human-attended; CPU time is irrelevant next to correctness. Performance effort is redirected into the *output format's* engine-friendliness, where perf actually lives for this project. |
| **`usize` permitted at std/zigimg API boundaries** (TigerStyle: avoid `usize`) | Standard-library and dependency signatures use `usize`; converting at every call would be noise. Domain code keeps explicitly sized types; the boundary is the only place `usize` appears. |

## Checklist before declaring a phase done

- [ ] `zig build` compiles clean.
- [ ] `zig build test` green, including negative-space tests.
- [ ] `zig fmt --check src/` clean.
- [ ] Every error path is either handled with a clear message or asserted with
      a comment explaining why it is a programmer error.
- [ ] Limits on loops/buffers exist and are asserted.
- [ ] New names use the project's nouns and follow the `.._px` / `.._max` /
      `.._count` suffix ordering.
- [ ] Commit message states why.
