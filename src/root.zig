const std = @import("std");
const Io = std.Io;

const palette = struct {
    colors: [256]color,

    //pub fn load(self: *palette, paletteFile: []const u8) void {
    //}
};

const color = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
};
