const std = @import("std");
const p2ts = @import("p2ts");

const ArgsError = error{InvalidArgument};
const ValidateError = error{ NoSource, NoDestination, NoPalette };
const ParseOutcome = union(enum) { parsed, help, version, invalid_argument: []const u8, missing_value: []const u8 };

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

const Arguments = struct {
    source: []const []const u8 = &.{},
    destination: ?[]const u8 = null,
    palette: ?[]const u8 = null,

    fn parse(self: *Arguments, arena: std.mem.Allocator, args: []const []const u8) !ParseOutcome {
        var sources: std.ArrayList([]const u8) = .empty;

        for (args[1..], 1..) |arg, i| {
            // flag -- are impair, so we use modulo to check if we are on a flag
            // TODO: Use a while to simplify this...
            if (@mod(i, 2) != 0) {
                if (!std.mem.startsWith(u8, arg, "--")) return .{ .invalid_argument = arg };
                const flag = std.meta.stringToEnum(Flag, arg[2..]) orelse return .{ .invalid_argument = arg };
                switch (flag) {
                    .source, .s => {
                        if (i + 1 >= args.len) return .{ .missing_value = arg };
                        try sources.append(arena, args[i + 1]);
                    },
                    .destination, .d => {
                        if (i + 1 >= args.len) return .{ .missing_value = arg };
                        self.destination = args[i + 1];
                    },
                    .palette, .p => {
                        if (i + 1 >= args.len) return .{ .missing_value = arg };
                        self.palette = args[i + 1];
                    },
                    .version, .v => {
                        return ParseOutcome.version;
                    },
                    .help, .h => {
                        return ParseOutcome.help;
                    },
                }
            } else {
                // cannot have two flag in a row
                if (std.mem.startsWith(u8, arg, "--")) {
                    return .{ .invalid_argument = arg };
                }
            }
        }

        self.source = sources.items;
        return ParseOutcome.parsed;
    }

    fn validate(self: Arguments) ValidateError!void {
        if (self.source.len == 0) return ValidateError.NoSource;
        if (self.destination == null) return ValidateError.NoDestination;
        if (self.palette == null) return ValidateError.NoPalette;
    }
};

pub fn main(init: std.process.Init) !u8 {
    const arena: std.mem.Allocator = init.arena.allocator();

    try printf(init.io, "pngs2tileset\n\n", .{});

    const args = try init.minimal.args.toSlice(arena);
    var arguments: Arguments = .{};
    switch (try arguments.parse(arena, args)) {
        .parsed => {},
        .help => {
            try printf(init.io, "usage: pngs2tileset [options] [source] [destination]\n", .{});
            return 0;
        },
        .version => {
            try printf(init.io, "version {s}\n", .{"x.x.x"});
            return 0;
        },
        .missing_value => |for_arg| {
            try printErrf(init.io, "error: missing value for argument {s}\n", .{for_arg});
            return 1;
        },
        .invalid_argument => |arg| {
            try printErrf(init.io, "error: invalid argument {s}\n", .{arg});
            return 1;
        },
    }

    _ = arguments.validate() catch |err| {
        switch (err) {
            ValidateError.NoSource => try printErrf(init.io, "error: no source specified\n", .{}),
            ValidateError.NoDestination => try printErrf(init.io, "error: no destination specified\n", .{}),
            ValidateError.NoPalette => try printErrf(init.io, "error: no palette specified\n", .{}),
        }
        return 1;
    };

    try printf(init.io, "creating tileset {s} from ", .{arguments.destination.?});
    for (arguments.source, 0..) |source, i| {
        if (i == 0) {
            try printf(init.io, "{s}", .{source});
        } else {
            try printf(init.io, ", {s}", .{source});
        }
    }
    try printf(init.io, "\ndone!\n", .{});

    return 0;
}

pub fn printTo(io: std.Io, file: std.Io.File, comptime fmt: []const u8, args: anytype) !void {
    var buf: [1024]u8 = undefined;
    const formatted = try std.mem.print(&buf, fmt, args);
    try file.writeStreamingAll(io, formatted);
}

pub fn printf(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    try printTo(io, std.Io.File.stdout(), fmt, args);
}

pub fn printErrf(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    try printTo(io, std.Io.File.stderr(), fmt, args);
}
