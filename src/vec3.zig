const std = @import("std");
const math = @import("std").math;

values: [3]f32,

const Self = @This();

fn unary_op(comptime self: *const Self, comptime op: fn (x: f32) anyerror!f32) ![3]f32 {
    return .{ try op(self.values[0]), try op(self.values[1]), try op(self.values[2]) };
}

fn binary_op(comptime self: *const Self, comptime other: *const Self, comptime op: fn (x: f32, y: f32) anyerror!f32) ![3]f32 {
    return .{ try op(self.values[0], other.values[0]), try op(self.values[1], other.values[1]), try op(self.values[2], other.values[2]) };
}

pub fn init(comptime e0: f32, comptime e1: f32, comptime e2: f32) Self {
    return .{
        .values = .{ e0, e1, e2 },
    };
}

pub fn assign(comptime self: *Self, comptime e0: f32, comptime e1: f32, comptime e2: f32) void {
    self.values[0] = e0;
    self.values[1] = e1;
    self.values[2] = e2;
}


pub fn x(comptime self: *const Self) f32 {
    return self.values[0];
}

pub fn y(comptime self: *const Self) f32 {
    return self.values[1];
}

pub fn z(comptime self: *const Self) f32 {
    return self.values[2];
}
pub fn r(comptime self: *const Self) f32 {
    return self.values[0];
}

pub fn g(comptime self: *const Self) f32 {
    return self.values[1];
}

pub fn b(comptime self: *const Self) f32 {
    return self.values[2];
}

pub fn squared_length(comptime self: *const Self) f32 {
    comptime var sq_len = 0.0;
    inline for (self.values) |v| {
        sq_len += v * v;
    }

    return sq_len;
}

pub fn length(comptime self: *const Self) f32 {
    return math.sqrt(self.squared_length());
}

pub fn scale(comptime self: *const Self, coeff: f32) Self {
    const op = struct {
        pub fn apply(v: f32) !f32 {
            return v * coeff;
        }
    }.apply;

    return .{ .values = try unary_op(self, op) };
}

pub fn normalized(comptime self: *const Self) Self {
    const len = comptime self.length();
    const op = struct {
        pub fn apply(v: f32) !f32 {
            return v / len;
        }
    }.apply;

    return .{ .values = try unary_op(self, op) };
}

pub fn negate(comptime self: *const Self) Self {
    const op = struct {
        pub fn apply(v: f32) !f32 {
            return -v;
        }
    }.apply;

    return .{ .values = try unary_op(self, op) };
}

pub fn add(comptime self: *const Self, comptime other: *const Self) Self {
    const op = struct {
        pub fn apply(lhs: f32, rhs: f32) !f32 {
            return lhs + rhs;
        }
    }.apply;
    return .{
        .values = try binary_op(self, other, op),
    };
}

pub fn sub(comptime self: *const Self, comptime other: *const Self) Self {
    const op = struct {
        pub fn apply(lhs: f32, rhs: f32) !f32 {
            return lhs - rhs;
        }
    }.apply;
    return .{
        .values = try binary_op(self, other, op),
    };
}

pub fn mul(comptime self: *const Self, comptime other: *const Self) Self {
    const op = struct {
        pub fn apply(lhs: f32, rhs: f32) !f32 {
            return lhs * rhs;
        }
    }.apply;
    return .{
        .values = try binary_op(self, other, op),
    };
}

pub fn div(comptime self: *const Self, comptime other: *const Self) Self {
    const op = struct {
        pub fn apply(lhs: f32, rhs: f32) !f32 {
            return lhs / rhs;
        }
    }.apply;
    return .{
        .values = try binary_op(self, other, op),
    };
}

pub fn dot(comptime self: *const Self, comptime other: *const Self) f32 {
    return self.x() * other.x() + self.y() * other.y() + self.z() * other.z();
}

pub fn cross(comptime self: *const Self, comptime other: *const Self) Self {
    return .{ .values = .{
        self.y() * other.z() - self.z() * other.y(),
        self.z() * other.x() - self.x() * other.z(),
        self.x() * other.y() - self.y() * other.x(),
    } };
}

pub fn inplace_add(comptime self: *Self, comptime other: *const Self) void {
    self.values[0] += other.values[0];
    self.values[1] += other.values[1];
    self.values[2] += other.values[2];
}

pub fn inplace_mul(comptime self: *Self, comptime other: *const Self) void {
    self.values[0] *= other.values[0];
    self.values[1] *= other.values[1];
    self.values[2] *= other.values[2];
}

pub fn inplace_scale(comptime self: *Self, coeff: f32) void {
    self.values[0] *= coeff;
    self.values[1] *= coeff;
    self.values[2] *= coeff;
}

test "initialize vector" {
    const v = comptime init(1.0, 2.0, 3.0);
    try std.testing.expectEqual(@as(f32, 1.0), v.x());
    try std.testing.expectEqual(@as(f32, 2.0), v.y());
    try std.testing.expectEqual(@as(f32, 3.0), v.z());
    try std.testing.expectEqual(@as(f32, 1.0), v.r());
    try std.testing.expectEqual(@as(f32, 2.0), v.g());
    try std.testing.expectEqual(@as(f32, 3.0), v.b());
}

test "calc squared length" {
    const v = comptime init(1.0, 2.0, 3.0);
    try std.testing.expectEqual(@as(f32, 14.0), v.squared_length());
}

test "calc length" {
    const v = comptime init(3.0, 4.0, 12.0);
    try std.testing.expectEqual(@as(f32, 13.0), v.length());
}

test "calc scale" {
    const v = comptime init(1.0, 2.0, 3.0);
    const sv = comptime v.scale(2.0);
    try std.testing.expectEqual(@as(f32, 2.0), sv.x());
    try std.testing.expectEqual(@as(f32, 4.0), sv.y());
    try std.testing.expectEqual(@as(f32, 6.0), sv.z());
}

test "calc normalized" {
    const v = comptime init(1.0, 2.0, 3.0);
    const nv = comptime v.normalized();
    try std.testing.expectApproxEqRel(@as(f32, 0.26726124), nv.x(), 1e-7);
    try std.testing.expectApproxEqRel(@as(f32, 0.53452248), nv.y(), 1e-7);
    try std.testing.expectApproxEqRel(@as(f32, 0.80178373), nv.z(), 1e-7);
}

test "calc negate" {
    const v = comptime init(1.0, 2.0, 3.0);
    const nv = comptime v.negate();
    try std.testing.expectEqual(@as(f32, -1.0), nv.x());
    try std.testing.expectEqual(@as(f32, -2.0), nv.y());
    try std.testing.expectEqual(@as(f32, -3.0), nv.z());
}

test "cacl add" {
    const v0 = comptime init(1.0, 2.0, 3.0);
    const v1 = comptime init(4.0, 5.0, 6.0);
    const v2 = comptime v0.add(&v1);
    try std.testing.expectEqual(@as(f32, 5.0), v2.x());
    try std.testing.expectEqual(@as(f32, 7.0), v2.y());
    try std.testing.expectEqual(@as(f32, 9.0), v2.z());
}

test "calc sub" {
    const v0 = comptime init(1.0, 2.0, 3.0);
    const v1 = comptime init(4.0, 5.0, 6.0);
    const v2 = comptime v0.sub(&v1);
    try std.testing.expectEqual(@as(f32, -3.0), v2.x());
    try std.testing.expectEqual(@as(f32, -3.0), v2.y());
    try std.testing.expectEqual(@as(f32, -3.0), v2.z());
}

test "calc mul" {
    const v0 = comptime init(1.0, 2.0, 3.0);
    const v1 = comptime init(4.0, 5.0, 6.0);
    const v2 = comptime v0.mul(&v1);
    try std.testing.expectEqual(@as(f32, 4.0), v2.x());
    try std.testing.expectEqual(@as(f32, 10.0), v2.y());
    try std.testing.expectEqual(@as(f32, 18.0), v2.z());
}

test "calc div" {
    const v0 = comptime init(1.0, 2.0, 3.0);
    const v1 = comptime init(4.0, 5.0, 6.0);
    const v2 = comptime v0.div(&v1);
    try std.testing.expectEqual(@as(f32, 0.25), v2.x());
    try std.testing.expectEqual(@as(f32, 0.4), v2.y());
    try std.testing.expectEqual(@as(f32, 0.5), v2.z());
}

test "calc dot" {
    const v0 = comptime init(1.0, 2.0, 3.0);
    const v1 = comptime init(4.0, 5.0, 6.0);
    try std.testing.expectEqual(@as(f32, 32.0), v0.dot(&v1));
}

test "calc cross" {
    const v0 = comptime init(1.0, 2.0, 3.0);
    const v1 = comptime init(4.0, 5.0, 6.0);
    const v2 = comptime v0.cross(&v1);
    try std.testing.expectEqual(@as(f32, -3.0), v2.x());
    try std.testing.expectEqual(@as(f32, 6.0), v2.y());
    try std.testing.expectEqual(@as(f32, -3.0), v2.z());
}
