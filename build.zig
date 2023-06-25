const std = @import("std");

fn parse_as_usize(may_value: ?[]const u8, default: usize) usize {
    if (may_value) |s| {
        var result: usize = 0;
        for (s) |c| {
            if (c < '0' or c > '9') return default;
            result *= 10;
            result += @intCast(usize, c - '0');
        }
        return result;
    }

    return default;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Initialize an allocator for the build script. This is the allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Create a map of environment variables.
    const env_map = try arena.allocator().create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(arena.allocator());
    defer env_map.deinit(); // technically unnecessary when using ArenaAllocator

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "comptime-ray-tracing",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const exe_options = b.addOptions();
    exe.addOptions("build_options", exe_options);
    exe_options.addOption(usize, "width", parse_as_usize(env_map.get("IMG_WIDTH"), 128));
    exe_options.addOption(usize, "height", parse_as_usize(env_map.get("IMG_HEIGHT"), 64));
    exe_options.addOption(usize, "samples_per_pixel", parse_as_usize(env_map.get("SAMPLES_PER_PIXEL"), 2));
    exe_options.addOption(usize, "chunk_count", parse_as_usize(env_map.get("CHUNK_COUNT"), 1));
    exe_options.addOption(usize, "chunk", parse_as_usize(env_map.get("CHUNK"), 0));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
