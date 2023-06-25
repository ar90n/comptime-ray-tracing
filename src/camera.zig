const std = @import("std");
const math = std.math;
const Ray = @import("ray.zig");
const Vec3 = @import("vec3.zig");
const Context = @import("context.zig");

const Self = @This();

origin: Vec3,
lower_left_corner: Vec3,
horizontal: Vec3,
vertical: Vec3,
u: Vec3,
v: Vec3,
w: Vec3,
lens_radius: f32,

pub fn init(
    comptime lookfrom: *const Vec3,
    comptime lookat: *const Vec3,
    comptime vup: *const Vec3,
    comptime vfov: f32,
    comptime aspect: f32,
    comptime aperture: f32,
    comptime focus_dist: f32,
) Self {
    const lens_radius = aperture / 2.0;
    const theta = vfov * math.pi / 180.0;
    const half_height = math.tan(theta / 2.0);
    const half_weight = aspect * half_height;

    const origin = comptime lookfrom.*;
    const w = comptime lookfrom.sub(lookat).normalized();
    const u = comptime vup.cross(&w).normalized();
    const v = comptime w.cross(&u);

    const forward = comptime w.scale(focus_dist);
    const half_horizontal = comptime u.scale(half_weight * focus_dist);
    const half_vertical = comptime v.scale(half_height * focus_dist);
    const lower_left_corner = comptime origin.sub(&half_horizontal).sub(&half_vertical).sub(&forward);
    const horizontal = comptime half_horizontal.scale(2.0);
    const vertical = comptime half_vertical.scale(2.0);

    return .{
        .origin = origin,
        .lower_left_corner = lower_left_corner,
        .horizontal = horizontal,
        .vertical = vertical,
        .u = u,
        .v = v,
        .w = w,
        .lens_radius = lens_radius,
    };
}

pub fn get_ray(comptime self: *const Self, comptime context: *Context, comptime s: f32, comptime t: f32) Ray {
    const rd = comptime random_in_unit_disk(context).scale(self.lens_radius);
    const offset = self.u.scale(rd.x()).add(&self.v.scale(rd.y()));
    const origin = self.origin.add(&offset);
    return comptime Ray.init(
        origin,
        self.lower_left_corner.add(&self.horizontal.scale(s)).add(&self.vertical.scale(t)).sub(&origin),
    );
}

fn random_in_unit_disk(comptime context: *Context) Vec3 {
    const origin = comptime Vec3.init(1.0, 1.0, 0.0);
    while (true) {
        const p = comptime Vec3.init(context.rand(), context.rand(), 0.0).sub(&origin);
        if (1.0 < p.dot(&p)) {
            return p;
        }
    }

    unreachable;
}

test "initialize camera" {
    comptime var lookfrom = Vec3.init(0.0, 0.0, 0.0);
    comptime var lookat = Vec3.init(0.0, 0.0, -1.0);
    comptime var vup = Vec3.init(0.0, 1.0, 0.0);
    comptime var vfov = 90.0;
    comptime var aspect = 2.0;
    comptime var aperture = 0.0;
    comptime var focus_dist = 1.0;

    const camera = Self.init(
        &lookfrom,
        &lookat,
        &vup,
        vfov,
        aspect,
        aperture,
        focus_dist,
    );
    _ = camera;

    //const ray = Self.get_ray(&camera, 0.0, 0.0);
    //const expected = Ray.init(
    //    &Vec3.init(0.0, 0.0, 0.0),
    //    &Vec3.init(0.0, 0.0, -1.0),
    //);
    //std.testing.expect(Vec3.equals(&ray.origin, &expected.origin));
    //std.testing.expect(Vec3.equals(&ray.direction, &expected.direction));
}
