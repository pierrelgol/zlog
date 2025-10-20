const std = @import("std");
const zdt = @import("zdt");

pub const LogLevel = enum {
    trace,
    debug,
    info,
    warn,
    err,
    fatal,

    pub fn stringFromLogLevel(self: LogLevel) []const u8 {
        return switch (self) {
            .trace => "[TRACE]",
            .debug => "[DEBUG]",
            .info => "[INFO ]",
            .warn => "[WARN ]",
            .err => "[ERROR]",
            .fatal => "[FATAL]",
        };
    }

    pub fn coloredStringFromLogLevel(self: LogLevel) []const u8 {
        return switch (self) {
            .trace => "\x1b[94m[TRACE]\x1b[0m",
            .debug => "\x1b[36m[DEBUG]\x1b[0m",
            .info => "\x1b[32m[INFO ]\x1b[0m",
            .warn => "\x1b[33m[WARN ]\x1b[0m",
            .err => "\x1b[31m[ERROR]\x1b[0m",
            .fatal => "\x1b[35m[FATAL]\x1b[0m",
        };
    }

    // Get the color code for message text
    pub fn messageColor(self: LogLevel) []const u8 {
        return switch (self) {
            .trace => "\x1b[94m", // Bright blue
            .debug => "\x1b[36m", // Cyan
            .info => "\x1b[32m", // Green
            .warn => "\x1b[33m", // Yellow
            .err => "\x1b[31m", // Red
            .fatal => "\x1b[1;35m", // Bold magenta
        };
    }

    pub fn formatColor(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("{s}", .{self.coloredStringFromLogLevel()});
    }

    pub fn formatNoColor(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("{s}", .{self.stringFromLogLevel()});
    }

    pub const format = formatNoColor;

    // Color reset
    pub const reset = "\x1b[0m";
    // Grey color for timestamps
    pub const grey = "\x1b[90m";
};

pub const LogTime = struct {
    date_time: zdt.Datetime,
    time_zone: ?zdt.Timezone,

    pub fn init(time_zone: ?zdt.Timezone) LogTime {
        return .{
            .date_time = .{},
            .time_zone = time_zone,
        };
    }

    pub fn now(self: *LogTime) void {
        if (self.time_zone) |tz| {
            self.date_time = zdt.Datetime.now(.{ .tz = &tz }) catch {
                self.date_time = zdt.Datetime.nowUTC();
                return;
            };
        } else {
            self.date_time = zdt.Datetime.nowUTC();
        }
    }

    pub fn formatFull(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try self.date_time.format(writer);
    }

    pub fn formatShort(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}", .{
            self.date_time.year,
            self.date_time.month,
            self.date_time.day,
            self.date_time.hour,
            self.date_time.minute,
            self.date_time.second,
        });
    }

    pub const format = formatShort;
};

// Private logger state struct
const LoggerState = struct {
    file: ?*std.Io.Writer,
    time: LogTime,
    level: LogLevel,
    quiet: bool,
    mutex: std.Thread.Mutex,

    fn log(self: *LoggerState, comptime lvl: LogLevel, src: ?std.builtin.SourceLocation, comptime str: []const u8, args: anytype) void {
        if (@intFromEnum(lvl) < @intFromEnum(self.level)) return;

        self.time.now();
        var time_buffer: [64]u8 = undefined;
        const time_str = std.fmt.bufPrint(&time_buffer, "{f}", .{self.time}) catch return;

        self.mutex.lock();
        defer self.mutex.unlock();
        {
            if (!self.quiet) {
                var stderr_buffer: [64]u8 = undefined;
                var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
                const stderr = &stderr_writer.interface;

                if (src) |location| {
                    // Format: [grey_timestamp] [colored_level] grey_location: colored_message
                    nosuspend stderr.print("{s}[{s}]{s} {s} {s}{s}:{d}:{s} {s}" ++ str ++ "{s}\n", .{
                        LogLevel.grey,
                        time_str,
                        LogLevel.reset,
                        lvl.coloredStringFromLogLevel(),
                        LogLevel.grey,
                        location.file,
                        location.line,
                        LogLevel.reset,
                        lvl.messageColor(),
                    } ++ args ++ .{LogLevel.reset}) catch return;
                } else {
                    // Format: [grey_timestamp] [colored_level] colored_message
                    nosuspend stderr.print("{s}[{s}]{s} {s} {s}" ++ str ++ "{s}\n", .{
                        LogLevel.grey,
                        time_str,
                        LogLevel.reset,
                        lvl.coloredStringFromLogLevel(),
                        lvl.messageColor(),
                    } ++ args ++ .{LogLevel.reset}) catch return;
                }
                stderr.flush() catch return;
            }
            if (self.file) |file| {
                if (src) |location| {
                    nosuspend file.print("[{s}] {s} {s}:{d}: " ++ str ++ "\n", .{ time_str, lvl.stringFromLogLevel(), location.file, location.line } ++ args) catch return;
                } else {
                    nosuspend file.print("[{s}] {s} " ++ str ++ "\n", .{ time_str, lvl.stringFromLogLevel() } ++ args) catch return;
                }
                file.flush() catch return;
            }
        }
    }
};

// Global singleton logger instance
var global_logger: LoggerState = .{
    .file = null,
    .time = LogTime.init(null),
    .level = .debug,
    .quiet = false,
    .mutex = .{},
};

// Initialize the global logger
pub fn init(file: ?*std.Io.Writer, time_zone: ?zdt.Timezone, level: LogLevel) void {
    global_logger.mutex.lock();
    defer global_logger.mutex.unlock();
    global_logger.file = file;
    global_logger.time = LogTime.init(time_zone);
    global_logger.level = level;
    global_logger.quiet = false;
}

// Set the minimum log level for the global logger
pub fn setLevel(level: LogLevel) void {
    global_logger.mutex.lock();
    defer global_logger.mutex.unlock();
    global_logger.level = level;
}

// Enable or disable quiet mode for the global logger
pub fn setQuiet(enable: bool) void {
    global_logger.mutex.lock();
    defer global_logger.mutex.unlock();
    global_logger.quiet = enable;
}

// Get the level string representation
pub fn levelString(level: LogLevel) []const u8 {
    return level.stringFromLogLevel();
}

// Module-level convenience functions that use the global logger
// Only trace exposes source location as an optional parameter
pub inline fn trace(comptime str: []const u8, args: anytype, src: ?std.builtin.SourceLocation) void {
    global_logger.log(.trace, src, str, args);
}

pub inline fn debug(comptime str: []const u8, args: anytype) void {
    global_logger.log(.debug, null, str, args);
}

pub inline fn info(comptime str: []const u8, args: anytype) void {
    global_logger.log(.info, null, str, args);
}

pub inline fn warn(comptime str: []const u8, args: anytype) void {
    global_logger.log(.warn, null, str, args);
}

pub inline fn err(comptime str: []const u8, args: anytype) void {
    global_logger.log(.err, null, str, args);
}

pub inline fn fatal(comptime str: []const u8, args: anytype) void {
    global_logger.log(.fatal, null, str, args);
}
