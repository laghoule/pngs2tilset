const std = @import("std");
const p2ts = @import("p2ts");

const argsError = error{ InvalidArgument, MissingArgument };

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

const ParseResult = enum { parsed, exit_ok };

const Arguments = struct {
    source: []const []const u8 = &.{},
    destination: ?[]const u8 = null,
    palette: ?[]const u8 = null,

    fn parse(self: *Arguments, arena: std.mem.Allocator, io: std.Io, args: []const []const u8) !ParseResult {
        var sources: std.ArrayList([]const u8) = .empty;

        for (args[1..], 1..) |arg, i| {
            if (@mod(i, 2) != 0) {
                if (i + 1 > args.len) return argsError.MissingArgument;
                if (!std.mem.startsWith(u8, arg, "--")) return argsError.InvalidArgument;

                const flag = std.meta.stringToEnum(Flag, arg[2..]) orelse return argsError.InvalidArgument; // TODO: print help when invalid
                switch (flag) {
                    .source, .s => {
                        try sources.append(arena, args[i + 1]);
                    },
                    .destination, .d => {
                        self.destination = args[i + 1];
                    },
                    .palette, .p => {
                        self.palette = args[i + 1];
                    },
                    .version, .v => {
                        try printf(io, "Here, we print version\n", .{});
                        return ParseResult.exit_ok;
                    },
                    .help, .h => {
                        // help is special and should be checked first
                        // not in this loop??
                        try printf(io, "Here, we print help\n", .{});
                        return ParseResult.exit_ok;
                    },
                }
            }
        }
        self.source = sources.items;
        return ParseResult.parsed;
    }

    fn validate(self: Arguments) argsError!void {
        if (self.source.len == 0) return argsError.MissingArgument;
        if (self.destination == null) return argsError.MissingArgument;
        if (self.palette == null) return argsError.MissingArgument;
    }
};

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    try printf(init.io, "pngs2tileset version {s}\n\n", .{"x.x.x"});

    const args = try init.minimal.args.toSlice(arena);
    var arguments: Arguments = .{};
    if (try arguments.parse(arena, init.io, args) == ParseResult.exit_ok) return ;
    try arguments.validate();

    try printf(init.io, "creating tileset {s} from ", .{arguments.destination.?});
    for (arguments.source, 0..) |source, i| {
        if (i == 0) {
            try printf(init.io, "{s}", .{source});
        } else {
            try printf(init.io, ", {s}", .{source});
        }
    }
    try printf(init.io, "\ndone!\n", .{});
}

pub fn printf(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    var buf: [1024]u8 = undefined;
    const formatted = try std.mem.print(&buf, fmt, args);
    try std.Io.File.stdout().writeStreamingAll(io, formatted);
}
