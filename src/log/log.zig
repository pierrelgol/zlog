const std = @import("std");
const zdt = @import("zdt");

pub const LogLevel = enum {
    debug,
    info,
    warn,
    err,
    fatal,

    pub fn stringFromLogLevel(self: LogLevel) []const u8 {
        return switch (self) {
            .debug => "[DEBUG]",
            .info => "[INFO ]",
            .warn => "[WARN ]",
            .err => "[ERROR]",
            .fatal => "[FATAL]",
        };
    }

    pub fn coloredStringFromLogLevel(self: LogLevel) []const u8 {
        return switch (self) {
            .debug => "\x1b[36m[DEBUG]\x1b[0m",
            .info => "\x1b[32m[INFO ]\x1b[0m",
            .warn => "\x1b[33m[WARN ]\x1b[0m",
            .err => "\x1b[31m[ERROR]\x1b[0m",
            .fatal => "\x1b[1;31m[FATAL]\x1b[0m",
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
            self.date_time = zdt.Datetime.now(.{ .tz = &tz }) catch |err| {
                _ = &err;
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

pub const Logger = struct {
    file: ?*std.Io.Writer,
    time: LogTime,
    level: LogLevel,

    pub fn init(file: ?*std.Io.Writer, time_zone: ?zdt.Timezone, level: LogLevel) Logger {
        return .{
            .file = file,
            .time = LogTime.init(time_zone),
            .level = level,
        };
    }

    fn log(self: *Logger, comptime lvl: LogLevel, comptime str: []const u8, comptime args: anytype) void {
        if (@intFromEnum(lvl) < @intFromEnum(self.level)) return;

        self.time.now();
        var time_buffer: [64]u8 = undefined;
        const time_str = std.fmt.bufPrint(&time_buffer, "{f}", .{self.time}) catch return;
        const lvl_str = lvl.stringFromLogLevel();

        var stderr_buffer: [64]u8 = undefined;
        const stderr = std.debug.lockStderrWriter(&stderr_buffer);
        defer std.debug.unlockStderrWriter();
        nosuspend stderr.print("[{s}] {s} " ++ str ++ "\n", .{ time_str, lvl_str } ++ args) catch return;

        if (self.file) |file| {
            nosuspend file.print("[{s}] {s} " ++ str ++ "\n", .{ time_str, lvl_str } ++ args) catch return;
        }
    }

    pub fn info(self: *Logger, comptime str: []const u8, comptime args: anytype) void {
        self.log(.info, str, args);
    }

    pub fn debug(self: *Logger, comptime str: []const u8, comptime args: anytype) void {
        self.log(.debug, str, args);
    }

    pub fn warn(self: *Logger, comptime str: []const u8, comptime args: anytype) void {
        self.log(.warn, str, args);
    }

    pub fn err(self: *Logger, comptime str: []const u8, comptime args: anytype) void {
        self.log(.err, str, args);
    }

    pub fn fatal(self: *Logger, comptime str: []const u8, comptime args: anytype) void {
        self.log(.fatal, str, args);
    }
};
