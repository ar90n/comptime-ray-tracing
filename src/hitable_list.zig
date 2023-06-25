const std = @import("std");
const Hitable = @import("hitable.zig").Hitable;
const HitRecord = @import("hit_record.zig");
const Ray = @import("ray.zig");

const Self = @This();

list: []Hitable,

pub fn init(comptime hitables: []Hitable) Self {
    return .{
        .list = hitables,
    };
}

pub fn hit(self: *const Self, comptime r: *const Ray, comptime t_min: f32, comptime t_max: f32) ?HitRecord {
    comptime var nearest_hit: ?HitRecord = null;
    comptime var t_far = t_max;
    for (self.list[0..]) |hitable| {
        switch (hitable) {
            .sphere => |sphere| {
                if (sphere.hit(r, t_min, t_far)) |rec| {
                    nearest_hit = rec;
                    t_far = rec.t;
                }
            },
        }
    }

    return nearest_hit;
}
