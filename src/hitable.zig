const Sphere = @import("sphere.zig");

pub const Hitable = union(enum) { sphere: Sphere };
