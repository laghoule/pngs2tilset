const std = @import("std");
const p2t = @import("p2ts");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing cmd args
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    try p2t.println(init.io, "pngs2tilset");
}
