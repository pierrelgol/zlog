const std = @import("std");
const zlog = @import("zlog");

pub fn main() !void {
    // Create a logger that logs to console only
    const tz = try zlog.zdt.Timezone.tzLocal(null);

    var logfile_buffer: [128]u8 = undefined;
    var logfile = try std.fs.cwd().createFile("logfile.log", .{});
    defer logfile.close();
    var logfile_writer = logfile.writer(&logfile_buffer);
    const log = &logfile_writer.interface;

    var logger = zlog.log.Logger.init(log, tz, .debug);

    // Test different log levels
    logger.info("This is an info message", .{});
    logger.warn("This is a warning message", .{});
    logger.err("This is an error message", .{});
    logger.fatal("This is a fatal message", .{});

    // Test with formatted arguments
    logger.info("User {s} logged in with ID {}", .{ "alice", 12345 });
    logger.warn("Memory usage is at {d}%", .{85});

    // Test level filtering - create a logger that only shows warnings and above
    var warn_logger = zlog.log.Logger.init(null, null, .warn);
    warn_logger.debug("This debug message should not appear", .{});
    warn_logger.info("This info message should not appear", .{});
    warn_logger.warn("This warning message should appear", .{});
    warn_logger.err("This error message should appear", .{});

    std.debug.print("Logger implementation complete!\n", .{});
}
