# pngs2tileset

`pngs2tileset` converts a list of RGBA PNG files (one PNG = one tile) plus a
GIMP palette (`.gpl`) into:

- a raw binary tileset (`.til`): 8-bit palette indices, tiles stacked
  vertically into a single tile-wide strip, no header — consumed directly by
  the [mquest](https://github.com/laghoule/mquest) 8086 engine;
- an assembly include file (`<destination>-refs.inc`) with tile dimensions,
  tile count, and one named constant per tile.

It is part of the mquest asset toolchain, alongside `png2pal`, `png2pic`,
`tiled2map`, and `gpl2asm`.

## Usage

```
pngs2tileset --source a.png b.png ... --palette p.gpl --destination out.til
```

Global flags: `--help`, `--version`.

**Under development.** `--version` and `--help` are the only flags currently
implemented; the rest of this interface is the work in progress — see
[TODO.md](TODO.md) for the phase plan and current state.

## Build

Requires [Zig 0.17.0](https://ziglang.org/download/). The sole dependency is
`zigimg`, fetched as a build dependency.

```sh
zig build        # compile and install into zig-out/
zig build test   # unit tests
```

## AI policy

All code in this project is **written by hand** — no AI-generated code is
used. AI tools serve strictly as a **learning aid and mentor**: they explain
concepts, decode compiler errors, and review documentation and code. They
never write source code on the user's behalf; the full collaboration protocol
lives in [AGENTS.md](AGENTS.md).

## License

GPL-3.0 — see [LICENSE](LICENSE).
