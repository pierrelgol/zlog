const std = @import("std");
const zlog = @import("zlog");

pub fn main() !void {
    std.debug.print("\n=== ZLog - Zig Logging Library Demo ===\n\n", .{});

    // Example 1: Using the global logger with default settings
    std.debug.print("--- Example 1: Global Logger (default) ---\n", .{});
    zlog.trace("This is a trace message with source location", .{}, @src());
    zlog.trace("This is a trace message without source location", .{}, null);
    zlog.debug("This is a debug message", .{});
    zlog.info("This is an info message", .{});
    zlog.warn("This is a warning message", .{});
    zlog.err("This is an error message", .{});
    zlog.fatal("This is a fatal message (highest priority)", .{});

    // Example 2: Global logger with formatted arguments
    std.debug.print("\n--- Example 2: Formatted Messages ---\n", .{});
    zlog.info("User {s} logged in with ID {d}", .{ "alice", 12345 });
    zlog.warn("Memory usage is at {d}%", .{85});
    zlog.err("Failed to open file: {s}", .{"/path/to/file.txt"});

    // Example 3: Configure global logger with file output
    std.debug.print("\n--- Example 3: Global Logger with File Output ---\n", .{});
    const tz = try zlog.zdt.Timezone.tzLocal(null);
    var logfile_buffer: [256]u8 = undefined;
    var logfile = try std.fs.cwd().createFile("logfile.log", .{});
    defer logfile.close();
    var logfile_writer = logfile.writer(&logfile_buffer);
    const log = &logfile_writer.interface;

    zlog.init(log, tz, .trace);
    zlog.trace("This trace with source goes to both stderr and logfile.log", .{}, @src());
    zlog.trace("This trace without source goes to both stderr and logfile.log", .{}, null);
    zlog.info("Check logfile.log to see all messages with timestamps", .{});

    // Example 4: Change log level at runtime
    std.debug.print("\n--- Example 4: Runtime Level Filtering ---\n", .{});
    zlog.setLevel(.warn);
    zlog.trace("This trace should NOT appear (filtered)", .{}, @src());
    zlog.debug("This debug should NOT appear (filtered)", .{});
    zlog.info("This info should NOT appear (filtered)", .{});
    zlog.warn("This warning SHOULD appear", .{});
    zlog.err("This error SHOULD appear", .{});

    // Example 5: Quiet mode (disable stderr output)
    std.debug.print("\n--- Example 5: Quiet Mode (file only) ---\n", .{});
    zlog.setQuiet(true);
    zlog.err("This error goes only to file, not stderr", .{});
    zlog.fatal("This fatal also only goes to file", .{});
    zlog.setQuiet(false);
    zlog.info("Stderr output re-enabled", .{});

    // Example 6: Multi-threaded logging
    std.debug.print("\n--- Example 6: Thread-safe Logging ---\n", .{});
    const thread1 = try std.Thread.spawn(.{}, logFromThread, .{ "Thread-1", 3 });
    const thread2 = try std.Thread.spawn(.{}, logFromThread, .{ "Thread-2", 3 });
    thread1.join();
    thread2.join();

    // Example 7: Level string utility
    std.debug.print("\n--- Example 7: Level String Utility ---\n", .{});
    inline for (@typeInfo(zlog.LogLevel).@"enum".fields) |field| {
        const level: zlog.LogLevel = @enumFromInt(field.value);
        std.debug.print("Level {s}: {s}\n", .{ field.name, zlog.levelString(level) });
    }

    std.debug.print("\n--- Demo Complete! Check logfile.log for file output ---\n", .{});
}

fn logFromThread(name: []const u8, count: usize) void {
    for (0..count) |i| {
        zlog.info("{s}: Message {d}", .{ name, i });
    }
}
