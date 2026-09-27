#!/bin/bash
set -euo pipefail
mkdir -p /build/source /build/results
cp -a /source/. /build/source/
cd /build/source
printf 'Started %s\n' "$(date -u --iso-8601=seconds)" > /build/results/status.txt
quartus_sh --flow compile projects/nes_pocket.qpf > /build/results/build.log 2>&1
find projects/output_files -maxdepth 1 -type f \( -name '*.rpt' -o -name '*.summary' \) -exec cp '{}' /build/results/ \;
cp projects/output_files/nes_pocket.rbf /build/results/nes.rbf
printf 'Completed %s\n' "$(date -u --iso-8601=seconds)" >> /build/results/status.txt
