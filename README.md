# comptime-ray-tracing
This repository contains a straightforward implementation of a ray tracing algorithm, as detailed in 'Ray Tracing in One Weekend', utilizing the unique capabilities of Zig's comptime evaluation."

# How to run
Rendering whole image at once.
```bash
$ zig build run > out.pgm
```

![128 x 64 output image](https://github.com/ar90n/comptime-ray-tracing/blob/assets/out_128_64.jpg?raw=true)

Rendering line by line.
```bash
$ gen.sh > out.pgm
```

![300 x 200 output image](https://github.com/ar90n/comptime-ray-tracing/blob/assets/out_300_200.jpg?raw=true)

# See Also
* [Ray Tracing in One Weekend](https://raytracing.github.io/)