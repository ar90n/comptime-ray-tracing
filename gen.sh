#!/usr/bin/bash
export IMG_WIDTH=300
export IMG_HEIGHT=200
export SAMPLES_PER_PIXEL=32
export CHUNK_COUNT=200
export CONCURRENT=1

seq 0 $(($CHUNK_COUNT-1)) | xargs -P $CONCURRENT -i bash -c 'export CHUNK={} && zig build --cache-dir zig-cache/chunk_{} -p zig-out/chunk_{}'

for i in $(seq 0 $(($CHUNK_COUNT-1))); do
    zig-out/chunk_${i}/bin/comptime-ray-tracing
done