const std = @import("std");
const Build = std.Build;
const Compile = Build.Step.Compile;

const srcdir = "raylib/raylib/src";

const raylib_flags = [_][]const u8{
    "-std=gnu99",
    "-DPLATFORM_DESKTOP",
    "-D_GNU_SOURCE",
    "-DGL_SILENCE_DEPRECATION=199309L",
    "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/1891
};

pub fn link(b: *Build, exe: *Compile, system_lib: bool) void {
    const mod = exe.root_module;
    mod.link_libc = true;

    if (system_lib) {
        mod.linkSystemLibrary("raylib", .{});
    } else {
        addRaylib(b, mod);
    }

    const target = mod.resolved_target orelse b.graph.host;
    const target_os = target.result.os.tag;
    switch (target_os) {
        .windows => {
            mod.linkSystemLibrary("winmm", .{});
            mod.linkSystemLibrary("gdi32", .{});
            mod.linkSystemLibrary("opengl32", .{});
        },
        .macos => {
            mod.linkFramework("OpenGL", .{});
            mod.linkFramework("Cocoa", .{});
            mod.linkFramework("IOKit", .{});
            mod.linkFramework("CoreAudio", .{});
            mod.linkFramework("CoreVideo", .{});
        },
        .freebsd, .openbsd, .netbsd, .dragonfly => {
            mod.linkSystemLibrary("GL", .{});
            mod.linkSystemLibrary("rt", .{});
            mod.linkSystemLibrary("dl", .{});
            mod.linkSystemLibrary("m", .{});
            mod.linkSystemLibrary("X11", .{});
            mod.linkSystemLibrary("Xrandr", .{});
            mod.linkSystemLibrary("Xinerama", .{});
            mod.linkSystemLibrary("Xi", .{});
            mod.linkSystemLibrary("Xxf86vm", .{});
            mod.linkSystemLibrary("Xcursor", .{});
        },
        else => { // linux and possibly others
            mod.linkSystemLibrary("GL", .{});
            mod.linkSystemLibrary("rt", .{});
            mod.linkSystemLibrary("dl", .{});
            mod.linkSystemLibrary("m", .{});
            mod.linkSystemLibrary("X11", .{});
        },
    }
}

fn addRaylib(b: *Build, mod: *Build.Module) void {
    mod.addIncludePath(b.path(srcdir ++ "/external/glfw/include"));

    mod.addCSourceFiles(.{
        .files = &.{
            srcdir ++ "/raudio.c",
            srcdir ++ "/rcore.c",
            srcdir ++ "/rmodels.c",
            srcdir ++ "/rshapes.c",
            srcdir ++ "/rtext.c",
            srcdir ++ "/rtextures.c",
            srcdir ++ "/utils.c",
        },
        .flags = &raylib_flags,
    });

    const target = mod.resolved_target orelse b.graph.host;
    switch (target.result.os.tag) {
        .windows => {
            mod.addCSourceFiles(.{ .files = &.{srcdir ++ "/rglfw.c"}, .flags = &raylib_flags });
            mod.addIncludePath(b.path(srcdir ++ "/external/glfw/deps/mingw"));
        },
        .macos => {
            mod.addCSourceFiles(.{
                .files = &.{srcdir ++ "/rglfw.c"},
                .flags = &raylib_flags ++ [_][]const u8{"-ObjC"},
            });
            mod.linkFramework("Foundation", .{});
            mod.linkFramework("CoreServices", .{});
            mod.linkFramework("CoreGraphics", .{});
            mod.linkFramework("AppKit", .{});
            mod.linkFramework("IOKit", .{});
        },
        else => {
            mod.addCSourceFiles(.{ .files = &.{srcdir ++ "/rglfw.c"}, .flags = &raylib_flags });
        },
    }
}

pub fn addAsPackage(b: *Build, name: []const u8, to: *Compile) void {
    const my_module = b.createModule(.{
        .root_source_file = b.path("raylib/lib/raylib-zig.zig"),
    });

    to.root_module.addImport(name, my_module);
}

pub const math = struct {
    pub fn addAsPackage(b: *Build, name: []const u8, to: *Compile) void {
        const my_module = b.createModule(.{
            .root_source_file = b.path("raylib/lib/raylib-zig-math.zig"),
        });

        to.root_module.addImport(name, my_module);
    }
};
