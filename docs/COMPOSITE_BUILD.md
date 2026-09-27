# Build and validation notes

## Source and compiler

- Base: [agg23/openFPGA-NES at `5bb74dc0c8717c4c04d1dfb5cac7412af273732c`](https://github.com/agg23/openFPGA-NES/tree/5bb74dc0c8717c4c04d1dfb5cac7412af273732c).
- Build version: `1.0.1-composite1`; package date: `2026-09-27`.
- Compiler: Quartus Prime Lite 21.1.1, build 850.
- Container: `ghcr.io/drizzt/quartus@sha256:b5b0f0b7af271a0b9e9adc0cad59ff773d8690742a1426500fd71056d2c09787`.
- Packaging helper: [agg23/pocketpublish at `55dff61f77a9d16ba3e4f42679b3c6426e0fc718`](https://github.com/agg23/pocketpublish/tree/55dff61f77a9d16ba3e4f42679b3c6426e0fc718).

## Measured results

Worst reported slack across the analyzed models, in nanoseconds:

| Variant | Setup | Hold | Logic utilization |
|---|---:|---:|---|
| NES | 0.384 | 0.104 | 18,343 / 18,480 (99%) |

Full compilation and FPGA fit succeeded. All reported setup, hold, recovery, removal and minimum pulse-width slacks are nonnegative, with zero total negative slack. No unconstrained clocks were reported. These results use the repository’s existing constraints and do not prove timing for unconstrained I/O or replace hardware testing.

The successful build has warnings and unconstrained external I/O, but no critical warnings were reported.

The build has one NES bitstream and uses the original placement seed 1.

## Hardware and simulation coverage

I’ve tried this build on my Pocket and haven’t noticed any obvious problems. I haven’t recorded specific game, firmware and display-mode coverage yet. Broader handheld/Dock, palette, Off/Full, save/load and Sleep/Wake testing is welcome on compatible games. This is not a claim of complete compatibility.

The standalone Icarus test covers disabled bypass, independent RGB arithmetic, odd-sum rounding, overflow, enable changes and blanking/line boundaries. Packaging verifies JSON, menu IDs, bitstream byte-wise reversal and archive integrity. Installed files were read back and checked by SHA-256 during initial testing.

## Integration

The menu uses ID `49` and bridge address `0x214`. Its enable bit is synchronized into the Pocket pixel clock domain. The filter averages the current and previous input pixel without adding a pixel-cycle pipeline delay. A line’s first pixel uses black as its left neighbor. Blanking invalidates history.

Blending occurs before the Pocket video-slot metadata is inserted. Sync/data-enable timing and save-state logic are not changed. The NES filter operates after palette conversion.

## Rebuild with Docker

These commands use a POSIX shell, including WSL, from the repository root. Docker stores Quartus and build databases in its configured data location. The pinned image occupies roughly 12 GB; allow additional working space. Use a fresh build volume/container name for each attempt.

```sh
docker volume create nes-composite-build
docker run --name nes-composite-build \
  --mount type=bind,source="$PWD",target=/source,readonly \
  --mount type=volume,source=nes-composite-build,target=/build \
  ghcr.io/drizzt/quartus@sha256:b5b0f0b7af271a0b9e9adc0cad59ff773d8690742a1426500fd71056d2c09787 \
  bash /source/tools/build-composite.sh
docker cp nes-composite-build:/build/results ./build-results
python3 tools/package-composite.py --results build-results --output release
```

Python 3.10 or newer is sufficient for packaging; no Python dependency installation is needed. The packaging tool rejects reported negative timing slack, missing memory-initialization files, failed compilation or unconstrained clocks. Review all compiler warnings too. A locally reproduced ZIP can differ in archive timestamps while containing identical payload files; compare per-file SHA-256 values in the manifests.

To rerun the filter simulation with Icarus installed:

```sh
iverilog -g2012 -s composite_blend_tb -o /tmp/composite-blend \
  target/pocket/composite_blend.sv tests/composite_blend_tb.sv
vvp /tmp/composite-blend
```
