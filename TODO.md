# TODO

`pngs2tileset` takes a list of RGBA PNGs (one PNG = one tile) plus a GIMP
palette (`.gpl`) and produces:

- a raw binary tileset (`.til`): 8-bit palette indices, tile by tile, row by
  row, no header;
- an assembly include file (`<destination>-refs.inc`) describing tile
  dimensions, tile count and named tile constants.

The output targets the same engine as `png2pal`/`tiled2map` (mquest), so the
rendering logic mirrors `png2pal`: nearest color by squared Euclidean distance
in RGB space, with index 0 reserved for transparency.

## Decisions

| Topic | Choice |
|---|---|
| Binary name | `pngs2tiles` |
| CLI | `pngs2tiles --source a.png b.png ... --palette p.gpl --destination out.til` plus `--help` / `--version` |
| Input | 1 PNG = 1 tile, stacked in order |
| Dimensions | All PNGs must share the same dimensions (this defines the tile size), otherwise error |
| Ordering | Alphabetical by file path, guaranteed by the tool |
| `.til` format | Raw, no header: 8-bit indices, tiles stacked vertically into one tile-wide strip (tile 0, then tile 1, ...), each tile row by row |
| Palette | GIMP `.gpl`, exactly 256 entries, index = line order, not embedded |
| PNG input | RGBA, remapped to nearest palette color (same logic as `png2pal`) |
| Transparency | alpha 0 -> index 0; partial alpha -> error |
| `.inc` | Auto-generated as `<destination-base>-refs.inc`, content still provisional |
| Errors | Fail-fast, exit code != 0, delete partial outputs |
| Tests | Unit tests only, run with `zig build test` |
| Zig | 0.17 + `zigimg` |
| Packaging | Fix the Dockerfile now, CI later, GPL-3.0 |

## Planned layout

```
src/main.zig   thin CLI (argument parsing, orchestration, exit codes)
src/root.zig   library API (re-exports)
src/pal.zig    .gpl parsing/validation + nearest color
src/img.zig    PNG decoding (zigimg) + RGBA -> index remap
src/til.zig    raw .til writer
src/inc.zig    .inc generation
```

## Phase 0 - Setup

- [ ] Rename the binary `png2til` -> `pngs2tiles` in `build.zig` and the `dockerfile`.
- [ ] Verify `zig build` and `zig build test` on Zig 0.17.

**Done when:** `zig-out/bin/pngs2tiles` is produced and build + tests are green.

## Phase 1 - CLI

- [ ] Parse arguments manually: `--source` (list), `--palette`, `--destination`, `--help`, `--version`.
- [ ] Validate that the three required options are present and at least one PNG is given.
- [ ] Print a clear usage message, write errors to stderr, exit 1.

**Done when:** `--help`, `--version`, missing arguments and unknown arguments all behave correctly.

## Phase 2 - `.gpl` palette

- [ ] `src/pal.zig`: `Palette` (256 colors), parse the GIMP header, `Name:`, `Columns:`, ignore `#` and blank lines.
- [ ] Strict validation: exactly 256 entries, RGB values in 0-255.
- [ ] Unit tests (valid palette, too short, invalid values).

**Done when:** tests are green and error messages are precise.

## Phase 3 - PNG loading + color remap

- [ ] `src/img.zig`: decode an RGBA PNG with `zigimg`, expose width/height/pixels.
- [ ] Check alpha: 0 -> index 0, partial -> error.
- [ ] `nearestColorIndex`: squared Euclidean distance, skip index 0 (same as `png2pal`).
- [ ] Unit tests on synthetic pixel data.

**Done when:** a PNG produces the correct index buffer and tests are green.

## Phase 4 - Multiple PNGs

- [ ] Sort paths alphabetically (independent of argument order).
- [ ] Check that all dimensions match, detailed error otherwise.
- [ ] Remap then concatenate the tiles.
- [ ] Unit tests on several in-memory images.

**Done when:** ordering is deterministic, dimensions are validated, concatenation is tested.

## Phase 5 - `.til` writer

- [ ] Write raw indices as a vertical stack of tiles (one tile-wide strip: tile 0, then tile 1, ...), each tile row by row, no header.
- [ ] Write through a temporary file + rename (no partial output).
- [ ] Check `size = tile_count x width x height`.

**Done when:** unit test on the buffer passes and the final file is written atomically.

## Phase 6 - `.inc`

- [ ] Automatic name: `<destination-base>-refs.inc` (e.g. `out.til` -> `out-refs.inc`).
- [ ] Constants `TILE_WIDTH`, `TILE_HEIGHT`, `TILES_COUNT`.
- [ ] One constant per tile named after its file, plus index/file comments.
- [ ] Mark the format as **provisional** in the code/README.

**Done when:** the `.inc` is consistent with the `.til` and the generator is tested.

## Phase 7 - Finishing touches

- [ ] Clean up partial outputs on any error.
- [ ] Consistent error messages and exit codes.
- [ ] `README.md`: usage + `.til` format.
- [ ] Renamed Dockerfile entrypoint.
- [x] Add `LICENSE` (GPL-3.0).

**Done when:** `zig build test` and `ReleaseFast` build pass, and a manual CLI smoke test works.

## Later / to decide

- Exact `.inc` format (to refine later).
- Deduplicate identical tiles (probably not).
- GitHub Actions release (multi-platform).
- Sprite sheet support - out of scope for now.
