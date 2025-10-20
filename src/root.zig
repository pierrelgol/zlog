const std = @import("std");
pub const zdt = @import("zdt");

// Re-export the log module
pub const log = @import("log/log.zig");

// Re-export public types
pub const LogTime = log.LogTime;
pub const LogLevel = log.LogLevel;

// Re-export global logger functions
pub const init = log.init;
pub const setLevel = log.setLevel;
pub const setQuiet = log.setQuiet;
pub const levelString = log.levelString;

// Re-export convenience logging functions
pub const trace = log.trace;
pub const debug = log.debug;
pub const info = log.info;
pub const warn = log.warn;
pub const err = log.err;
pub const fatal = log.fatal;
