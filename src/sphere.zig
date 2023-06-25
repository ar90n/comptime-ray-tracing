const std = @import("std");
const math = std.math;
const Vec3 = @import("vec3.zig");
const Ray = @import("ray.zig");
const HitRecord = @import("hit_record.zig");
const Material = @import("material.zig").Material;

const Self = @This();

center: Vec3,
radius: f32,
material: Material,

pub fn init(comptime center: Vec3, comptime radius: f32, comptime material: Material) Self {
    return Self{ .center = center, .radius = radius, .material = material };
}

pub fn hit(self: *const Self, comptime r: *const Ray, comptime t_min: f32, comptime t_max: f32) ?HitRecord {
    const oc = comptime r.origin().sub(&self.center);
    const a = comptime r.direction().dot(r.direction());
    const b = comptime 2.0 * oc.dot(r.direction());
    const c = comptime oc.dot(&oc) - self.radius * self.radius;
    const discriminant = b * b - 4.0 * a * c;
    if (0.0 < discriminant) {
        const near_t = -(b + math.sqrt(discriminant)) / (2.0 * a);
        if ((t_min < near_t) and (near_t < t_max)) {
            const t = near_t;
            const p = comptime r.point_at_parameter(t);
            const normal = p.sub(&self.center).scale(1.0 / self.radius);
            return .{
                .t = t,
                .p = p,
                .normal = normal,
                .material = self.material,
            };
        }

        const far_t = -(b - math.sqrt(discriminant)) / (2.0 * a);
        if ((t_min < far_t) and (far_t < t_max)) {
            const t = far_t;
            const p = comptime r.point_at_parameter(t);
            const normal = p.sub(&self.center).scale(1.0 / self.radius);
            return .{
                .t = t,
                .p = p,
                .normal = normal,
                .material = self.material,
            };
        }
    }

    return null;
}
