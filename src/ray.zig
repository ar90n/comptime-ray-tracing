const std = @import("std");
const Vec3 = @import("vec3.zig");

const Self = @This();

org: Vec3,
dir: Vec3,

pub fn init(org: Vec3, dir: Vec3) Self {
    return Self{ .org = org, .dir = dir };
}

pub fn origin(self: *const Self) *const Vec3 {
    return &self.org;
}

pub fn direction(self: *const Self) *const Vec3 {
    return &self.dir;
}

pub fn point_at_parameter(self: *const Self, t: f32) Vec3 {
    return Vec3.add(self.origin(), &Vec3.scale(self.direction(), t));
}

test "initialize Self" {
    const ray = comptime Self.init(Vec3.init(1.0, 2.0, 3.0), Vec3.init(4.0, 5.0, 6.0));
    try std.testing.expectEqual(@as(f32, 1.0), comptime ray.origin().x());
    try std.testing.expectEqual(@as(f32, 2.0), comptime ray.origin().y());
    try std.testing.expectEqual(@as(f32, 3.0), comptime ray.origin().z());
    try std.testing.expectEqual(@as(f32, 4.0), comptime ray.direction().x());
    try std.testing.expectEqual(@as(f32, 5.0), comptime ray.direction().y());
    try std.testing.expectEqual(@as(f32, 6.0), comptime ray.direction().z());
}

test "point_at_parameter" {
    const ray = comptime Self.init(Vec3.init(1.0, 2.0, 3.0), Vec3.init(4.0, 5.0, 6.0));
    const point = comptime ray.point_at_parameter(2.0);
    try std.testing.expectEqual(@as(f32, 9.0), comptime point.x());
    try std.testing.expectEqual(@as(f32, 12.0), comptime point.y());
    try std.testing.expectEqual(@as(f32, 15.0), comptime point.z());
}
