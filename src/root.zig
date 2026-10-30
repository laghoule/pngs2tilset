const std = @import("std");
const Io = std.Io;

pub fn printf(io: Io, comptime fmt: []const u8, args: anytype) !void {
    var buf: [1024]u8 = undefined;
    const formatted = try std.mem.print(&buf, fmt, args);
    try std.Io.File.stdout().writeStreamingAll(io, formatted);
}
