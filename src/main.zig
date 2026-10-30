const std = @import("std");
const p2ts = @import("p2ts");

const argsError = error{InvalidArgument};

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

    try p2ts.printf(init.io, "pngs2tileset version {s}\n", .{"x.x.x"});

    const args = try init.minimal.args.toSlice(arena);
    for (args[1..]) |arg| {
        std.log.info("arg: {s}", .{arg});
        if (!std.mem.startsWith(u8, arg, "--")) return argsError.InvalidArgument;
        const flag = std.meta.stringToEnum(Flag, arg[2..]) orelse return argsError.InvalidArgument; // TODO: print help when invalid
        switch (flag) {
            .source, .s => {
                try p2ts.printf(init.io, "{s}", .{"source"});
            },
            .destination, .d => {
                try p2ts.printf(init.io, "{s}", .{"destination"});
            },
            .palette, .p => {
                try p2ts.printf(init.io, "{s}", .{"palette"});
            },
            .version, .v => {
                try p2ts.printf(init.io, "{s}", .{"version"});
            },
            .help, .h => {
                try p2ts.printf(init.io, "{s}", .{"help"});
            },
        }
    }
}
