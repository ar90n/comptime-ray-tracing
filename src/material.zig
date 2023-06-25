const std = @import("std");
const math = std.math;
const prng = std.rand.DefaultPrng;
const HitRecord = @import("hit_record.zig");
const Ray = @import("ray.zig");
const Vec3 = @import("vec3.zig");
const Context = @import("context.zig");

fn random_in_unit_sphere(comptime context: *Context) Vec3 {
    const r = comptime context.rand();
    const theta = comptime 2.0 * math.pi * context.rand();
    const phi = comptime 2.0 * math.pi * context.rand();
    return polar_to_cartesian(r, theta, phi);
}

fn polar_to_cartesian(comptime r: f32, comptime theta: f32, comptime phi: f32) Vec3 {
    return Vec3.init(
        r * math.sin(phi) * math.cos(theta),
        r * math.sin(phi) * math.sin(theta),
        r * math.cos(phi),
    );
}

fn reflect(comptime v: *const Vec3, comptime n: *const Vec3) Vec3 {
    return v.sub(&n.scale(2.0 * v.dot(n)));
}

fn refract(comptime v: *const Vec3, comptime n: *const Vec3, comptime ni_over_nt: f32) ?Vec3 {
    const uv = comptime v.normalized();
    const dt = comptime uv.dot(n);
    const discriminant = 1.0 - ni_over_nt * ni_over_nt * (1.0 - dt * dt);
    if (discriminant <= 0.0) {
        return null;
    }

    return comptime uv.sub(&n.scale(dt)).scale(ni_over_nt).sub(&n.scale(math.sqrt(discriminant)));
}

fn schlick(comptime cosine: f32, comptime ref_idx: f32) f32 {
    const r0 = comptime brk: {
        const r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
        break :brk r0 * r0;
    };
    return r0 + (1.0 - r0) * math.pow(f32, (1.0 - cosine), 5.0);
}

pub const ScatterResult = struct {
    attenuation: Vec3,
    scattered: Ray,
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,
};

pub const Lambertian = struct {
    albedo: Vec3,

    pub fn init(albedo: Vec3) Lambertian {
        return .{ .albedo = albedo };
    }

    pub fn scatter(comptime self: *const Lambertian, comptime context: *Context, comptime r_in: *const Ray, comptime rec: *const HitRecord) ?struct { Vec3, Ray } {
        _ = r_in;
        const target = comptime rec.p.add(&rec.normal).add(&random_in_unit_sphere(context));
        return comptime .{ self.albedo, Ray.init(rec.p, target.sub(&rec.p)) };
    }
};

pub const Metal = struct {
    albedo: Vec3,
    fuzz: f32,

    pub fn init(albedo: Vec3, fuzz: f32) Metal {
        return .{ .albedo = albedo, .fuzz = @min(1.0, fuzz) };
    }

    pub fn scatter(comptime self: *const Metal, comptime context: *Context, comptime r_in: *const Ray, comptime rec: *const HitRecord) ?struct { Vec3, Ray } {
        const reflected = reflect(r_in.direction(), &rec.normal);
        const scattered = Ray.init(rec.p, reflected.add(&random_in_unit_sphere(context).scale(self.fuzz)));
        if (reflected.dot(&rec.normal) <= 0.0) {
            return null;
        }

        return comptime .{ self.albedo, scattered };
    }
};

pub const Dielectric = struct {
    ref_idx: f32,

    pub fn init(ref_idx: f32) Dielectric {
        return .{ .ref_idx = ref_idx };
    }

    pub fn scatter(comptime self: *const Dielectric, comptime context: *Context, comptime r_in: *const Ray, comptime rec: *const HitRecord) ?struct { Vec3, Ray } {
        const cosine = comptime r_in.direction().dot(&rec.normal) / r_in.direction().length();
        const outward_normal = comptime if (0.0 < cosine) rec.normal.negate() else rec.normal;
        const ni_over_nt = comptime if (0.0 < cosine) self.ref_idx else 1.0 / self.ref_idx;
        const cosine_coeff = comptime if (0.0 < cosine) self.ref_idx else -1.0;

        const scattered = comptime brk: {
            if (refract(r_in.direction(), &outward_normal, ni_over_nt)) |refracted| {
                const mod_cosine = cosine_coeff * cosine;
                const refract_prob = schlick(mod_cosine, self.ref_idx);
                if (refract_prob < context.rand()) {
                    break :brk refracted;
                }
            }

            break :brk reflect(r_in.direction(), &rec.normal);
        };

        const attenuation = Vec3.init(1.0, 1.0, 1.0);
        return comptime .{ attenuation, Ray.init(rec.p, scattered) };
    }
};
