const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const target = std.Target.Query{ .cpu_arch = .x86_64, .os_tag = .freestanding, .abi = .none };

    const exe = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = b.createModule(.{ .root_source_file = b.path("src/kernel/main.zig"), .optimize = optimize, .target = b.resolveTargetQuery(target) }),
    });

    const kernel_bin = exe.getEmittedBin();
    const install_kernel = b.addInstallFile(kernel_bin, "boot/kernel");
    b.getInstallStep().dependOn(&install_kernel.step);

    // Set linker script for kernel layout
    exe.addLinkerArg("-T");
    exe.addLinkerArg(b.path("linker.ld").getPath(b));

    exe.root_module.strip = true;

    b.installArtifact(exe);
}
