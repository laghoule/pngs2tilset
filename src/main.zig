const std = @import("std");
const p2ts = @import("p2ts");

const argsError = error{InvalidArgument};

pub fn printf(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    var buf: [1024]u8 = undefined;
    const formatted = try std.mem.print(&buf, fmt, args);
    try std.Io.File.stdout().writeStreamingAll(io, formatted);
}

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const Flag = enum {
        source,
        destination,
        palette,
        version,
        help,
        s,
        d,
        p,
        v,
        h,
    };

    try printf(init.io, "pngs2tileset version {s}\n", .{"x.x.x"});

    const args = try init.minimal.args.toSlice(arena);
    for (args[1..]) |arg| {
        std.log.info("arg: {s}", .{arg});
        if (!std.mem.startsWith(u8, arg, "--")) return argsError.InvalidArgument;
        const flag = std.meta.stringToEnum(Flag, arg[2..]) orelse return argsError.InvalidArgument; // TODO: print help when invalid
        switch (flag) {
            .source, .s => {
                try printf(init.io, "{s}", .{"source"});
            },
            .destination, .d => {
                try printf(init.io, "{s}", .{"destination"});
            },
            .palette, .p => {
                try printf(init.io, "{s}", .{"palette"});
            },
            .version, .v => {
                try printf(init.io, "{s}", .{"version"});
            },
            .help, .h => {
                try printf(init.io, "{s}", .{"help"});
            },
        }
    }
}
