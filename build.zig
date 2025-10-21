const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "quixil",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .use_llvm = optimize != .Debug,
        // .use_llvm = true,
        .strip = true,
    });

    exe.linkLibC();
    exe.addIncludePath(b.path("dependencies"));
    exe.addCSourceFile(.{
        .file = b.path("src/termbox.c"),
        .flags = &.{}});

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
