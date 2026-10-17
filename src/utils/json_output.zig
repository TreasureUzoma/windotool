const std = @import("std");

/// JSON Output Writer for structured command results
pub const JsonWriter = struct {
    allocator: std.mem.Allocator,
    enabled: bool,

    pub fn init(allocator: std.mem.Allocator, enabled: bool) JsonWriter {
        return .{
            .allocator = allocator,
            .enabled = enabled,
        };
    }

    /// Output a success response with data (as anonymous struct)
    pub fn writeSuccess(self: JsonWriter, data: anytype) !void {
        if (!self.enabled) return;

        var string: std.ArrayList(u8) = .empty;
        defer string.deinit(self.allocator);

        const writer = string.writer(self.allocator);
        
        try writer.writeAll("{\"success\":true,\"data\":");
        try writeJsonValue(writer, data);
        try writer.writeAll("}\n");

        std.debug.print("{s}", .{string.items});
    }

    /// Output an error response
    pub fn writeError(self: JsonWriter, message: []const u8, err_code: ?[]const u8) !void {
        if (!self.enabled) return;

        var string: std.ArrayList(u8) = .empty;
        defer string.deinit(self.allocator);

        const writer = string.writer(self.allocator);
        
        try writer.writeAll("{\"success\":false,\"error\":\"");
        try writeEscapedString(writer, message);
        try writer.writeAll("\"");
        if (err_code) |code| {
            try writer.writeAll(",\"code\":\"");
            try writeEscapedString(writer, code);
            try writer.writeAll("\"");
        }
        try writer.writeAll("}\n");

        std.debug.print("{s}", .{string.items});
    }

    /// Check if JSON output is enabled
    pub fn isEnabled(self: JsonWriter) bool {
        return self.enabled;
    }
};

// Helper to write JSON values from anonymous structs
fn writeJsonValue(writer: anytype, value: anytype) !void {
    const T = @TypeOf(value);
    const type_info = @typeInfo(T);
    
    switch (type_info) {
        .@"struct" => |struct_info| {
            if (struct_info.is_tuple) {
                // Handle tuple as array
                try writer.writeAll("[");
                inline for (value, 0..) |item, i| {
                    if (i > 0) try writer.writeAll(",");
                    try writeJsonValue(writer, item);
                }
                try writer.writeAll("]");
            } else {
                // Handle struct as object
                try writer.writeAll("{");
                inline for (struct_info.fields, 0..) |field, i| {
                    if (i > 0) try writer.writeAll(",");
                    try writer.print("\"{s}\":", .{field.name});
                    try writeJsonValue(writer, @field(value, field.name));
                }
                try writer.writeAll("}");
            }
        },
        .int, .comptime_int => {
            try writer.print("{d}", .{value});
        },
        .float, .comptime_float => {
            try writer.print("{d}", .{value});
        },
        .bool => {
            try writer.writeAll(if (value) "true" else "false");
        },
        .pointer => |ptr_info| {
            if (ptr_info.child == u8) {
                // String
                try writer.writeAll("\"");
                try writeEscapedString(writer, value);
                try writer.writeAll("\"");
            } else {
                try writer.writeAll("null");
            }
        },
        .optional => {
            if (value) |v| {
                try writeJsonValue(writer, v);
            } else {
                try writer.writeAll("null");
            }
        },
        .null => {
            try writer.writeAll("null");
        },
        else => {
            try writer.writeAll("null");
        },
    }
}

fn writeEscapedString(writer: anytype, s: []const u8) !void {
    for (s) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
}
