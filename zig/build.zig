const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{
        .name = "gitter",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const lib_unit_tests = b.addTest(.{
    //     .root_module = lib_mod,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_module = exe_mod,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);

    // Add multi-target builds for major platforms
    //     const targets: []const std.Target.Query = &.{
    //     .{ .cpu_arch = .aarch64, .os_tag = .macos },
    //     .{ .cpu_arch = .aarch64, .os_tag = .linux },
    //     .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    //     .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    //     .{ .cpu_arch = .x86_64, .os_tag = .windows },
    // };

    //  for (targets) |t| {
    //         const exe = b.addExecutable(.{
    //             .name = "gitter",
    //             .root_source_file = b.path("src/main.zig"),
    //             .target = b.resolveTargetQuery(t),
    //             .optimize = .ReleaseFast,
    //         });

    //         const target_output = b.addInstallArtifact(exe, .{
    //             .dest_dir = .{
    //                 .override = .{
    //                     .custom = try t.zigTriple(b.allocator),
    //                 },
    //             },
    //         });

    //         b.getInstallStep().dependOn(&target_output.step);
    //     }
}
