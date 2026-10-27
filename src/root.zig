const std = @import("std");
const Io = std.Io;

pub fn println(io: Io, message: []const u8) Io.Writer.Error!void {
    var buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try stdout_writer.print("{s}\n", .{message});
    try stdout_writer.flush();
}
