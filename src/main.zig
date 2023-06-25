const build_options = @import("build_options");
const std = @import("std");
const time = std.time;
const math = std.math;
const Context = @import("context.zig");
const Vec3 = @import("vec3.zig");
const Ray = @import("ray.zig");
const HitableList = @import("hitable_list.zig");
const Hitable = @import("hitable.zig").Hitable;
const Camera = @import("camera.zig");
const Sphere = @import("sphere.zig");
const Lambertian = @import("material.zig").Lambertian;
const Metal = @import("material.zig").Metal;
const Dielectric = @import("material.zig").Dielectric;

fn color(comptime context: *Context, comptime r: *const Ray, comptime world: *const HitableList, depth: u32, comptime out: *Vec3) void {
    if (world.hit(r, 0.001, 1000.0)) |rec| {
        const may_scattered = comptime switch (rec.material) {
            .dielectric => |material| material.scatter(context, r, &rec),
            .lambertian => |material| material.scatter(context, r, &rec),
            .metal => |material| material.scatter(context, r, &rec),
        };

        if (may_scattered) |scattered| {
            if (depth < 25) {
                color(context, &scattered[1], world, depth + 1, out);
                out.inplace_mul(&scattered[0]);
            } else {
                out.assign(0.0, 0.0, 0.0);
            }
            return;
        }
    }

    const unit_direction = comptime r.direction().normalized();
    const t = comptime 0.5 * (unit_direction.y() + 1.0);
    out.assign(1.0 * (1.0 - t) + 0.5 * t, 1.0 * (1.0 - t) + 0.7 * t, 1.0 * (1.0 - t) + 1.0 * t);
}

fn random_scene(comptime context: *Context, comptime n: usize) !HitableList {
    const ns: usize = n * n + 4;
    comptime var hitables: [ns]Hitable = undefined;
    comptime var i = 0;
    hitables[i] = comptime .{ .sphere = Sphere.init(
        Vec3.init(0.0, -1000.0, 0.0),
        1000.0,
        .{ .lambertian = Lambertian.init(Vec3.init(0.5, 0.5, 0.5)) },
    ) };
    i += 1;

    hitables[i] = comptime .{ .sphere = Sphere.init(
        Vec3.init(0.0, 1.0, 0.0),
        1.0,
        .{ .dielectric = Dielectric.init(1.5) },
    ) };
    i += 1;

    hitables[i] = comptime .{ .sphere = Sphere.init(
        Vec3.init(-4.0, 1.0, 0.0),
        1.0,
        .{ .lambertian = Lambertian.init(Vec3.init(0.4, 0.2, 0.1)) },
    ) };
    i += 1;

    hitables[i] = comptime .{ .sphere = Sphere.init(
        Vec3.init(4.0, 1.0, 0.0),
        1.0,
        .{ .metal = Metal.init(Vec3.init(0.7, 0.6, 0.5), 0.0) },
    ) };
    i += 1;

    const half_n = comptime @as(i32, n) / 2;
    for (0..n) |a| {
        for (0..n) |b| {
            const radius = comptime 0.1 + 0.25 * context.rand();
            const center = comptime Vec3.init(
                @as(f32, (@as(i32, a) - half_n)) + 0.9 * context.rand(),
                radius,
                @as(f32, (@as(i32, b) - half_n)) + 0.9 * context.rand(),
            );
            const choice = comptime context.rand();
            const material = comptime brk: {
                if (choice < 0.8) {
                    break :brk .{ .lambertian = Lambertian.init(Vec3.init(
                        context.rand() * context.rand(),
                        context.rand() * context.rand(),
                        context.rand() * context.rand(),
                    )) };
                } else if (choice < 0.95) {
                    break :brk .{ .metal = Metal.init(
                        Vec3.init(
                            0.5 * (1.0 + context.rand()),
                            0.5 * (1.0 + context.rand()),
                            0.5 * (1.0 - context.rand()),
                        ),
                        0.5 * context.rand(),
                    ) };
                } else {
                    break :brk .{ .dielectric = Dielectric.init(1.5) };
                }
            };

            hitables[i] = comptime .{
                .sphere = Sphere.init(
                    center,
                    radius,
                    material,
                ),
            };
            i += 1;
        }
    }

    return HitableList.init(&hitables);
}

fn calc_color(comptime context: *Context, comptime cam: *const Camera, comptime world: *const HitableList, comptime nx: usize, comptime ny: usize, comptime ns: usize, comptime x: usize, comptime y: usize) Vec3 {
    comptime var acc_col = Vec3.init(0.0, 0.0, 0.0);
    comptime var tmp_col = Vec3.init(0.0, 0.0, 0.0);
    for (0..ns) |_| {
        const u = (@as(f32, x) + context.rand()) / @as(f32, nx);
        const v = (@as(f32, y) + context.rand()) / @as(f32, ny);
        const r = cam.get_ray(context, u, v);
        color(context, &r, world, 0, &tmp_col);
        acc_col.inplace_add(&tmp_col);
    }
    acc_col.inplace_scale(1.0 / @as(f32, ns));
    return comptime Vec3.init(math.sqrt(acc_col.x()), math.sqrt(acc_col.y()), math.sqrt(acc_col.z()));
}

pub fn main() !void {
    @setEvalBranchQuota(0xffffffff);

    comptime var nx = build_options.width;
    comptime var ny = build_options.height;
    comptime var ns = build_options.samples_per_pixel;
    comptime var chunk_count = build_options.chunk_count;
    comptime var chunk = build_options.chunk;

    comptime var context = Context.init();
    const world = comptime try random_scene(&context, 8);
    const lookfrom = comptime Vec3.init(-15.0, 4.0, 10.0);
    const lookat = comptime Vec3.init(0.0, 1.0, 0.0);
    const vup = comptime Vec3.init(0.0, -1.0, 0.0);
    const dist_to_focus = comptime lookfrom.sub(&lookat).length();
    const aperture: comptime_float = 2.0;
    const aspect: comptime_float = @as(f32, nx) / @as(f32, ny);
    const cam = comptime Camera.init(
        &lookfrom,
        &lookat,
        &vup,
        25.0,
        aspect,
        aperture,
        dist_to_focus,
    );

    const chunk_size = comptime (ny + chunk_count - 1) / chunk_count;
    comptime var buf: [chunk_size][nx][3]u8 = undefined;
    const beg_y = comptime chunk * chunk_size;
    const end_y = comptime @min((chunk + 1) * chunk_size, ny);
    inline for (beg_y..end_y) |y| {
        inline for (0..nx) |x| {
            const col = comptime calc_color(&context, &cam, &world, nx, ny, ns, x, y);
            const i = x;
            const j = comptime y - beg_y;
            buf[j][i][0] = comptime @intFromFloat(u8, (255.99 * col.r()));
            buf[j][i][1] = comptime @intFromFloat(u8, (255.99 * col.g()));
            buf[j][i][2] = comptime @intFromFloat(u8, (255.99 * col.b()));
        }
    }

    const stdout = std.io.getStdOut().writer();
    if (chunk == 0) {
        try stdout.print("P3\n", .{});
        try stdout.print("{} {}\n", .{ nx, ny });
        try stdout.print("255\n", .{});
    }

    for (0..chunk_size) |j| {
        for (0..nx) |i| {
            const c = buf[j][i];
            try stdout.print("{} {} {}\n", .{ c[0], c[1], c[2] });
        }
    }
}
