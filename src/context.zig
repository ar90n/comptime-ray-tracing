const std = @import("std");
const prng = std.rand.DefaultPrng;

const Self = @This();

rnd: prng,

pub fn init() Self {
    return .{
        .rnd = prng.init(42),
    };
}

pub fn rand(self: *Self) f32 {
    return self.rnd.random().float(f32);
}
