const std = @import("std");
pub usingnamespace @import("./Formatter/property.zig");

pub fn format(allocator: *std.mem.Allocator, string: []const u8, prop: []Property) ![]const u8 {
    var str = std.ArrayList(u8).init(allocator);

    var i: usize = 0;
    while (true) {
        if (i == prop.len) break;
        _ = try prop[i].write(str.writer());
        i += 1;
    }

    for (string) |char| {
        if (char == '%') {
            try str.appendSlice("%%");
        } else {
            try str.append(char);
        }
    }
    i -= 1;
    while (true) {
        if (prop[i].close()) |p| {
            _ = try p.write(str.writer());
        }
        if (i == 0) break;
        i -= 1;
    }

    return str.toOwnedSlice();
}

pub fn unformat(allocator: *std.mem.Allocator, string: []const u8) ![]const u8 {
    var str = std.ArrayList(u8).init(allocator);
    var i: usize = 0;
    while (i < string.len) : (i += 1) {
        if (string[i] == '%') {
            if (string[i + 1] == '%') {
                try str.append(string[i]);
                continue;
            }
            var l = std.mem.indexOf(u8, string[i..], "}");
            if (l) |idx| i += idx;
        } else {
            try str.append(string[i]);
        }
    }
    return str.toOwnedSlice();
}

test "format string" {
    var prop = [_]Property{
        .swap,
        .{ .offset = 16 },
        .{ .background = comptime try Color.fromString("#deadbeef") },
    };
    var str1 = try format(std.testing.allocator, "Hello, World!", &prop);
    defer std.testing.allocator.free(str1);
    var str2 = try format(std.testing.allocator, "Battery: 100%", &prop);
    defer std.testing.allocator.free(str2);

    std.testing.expectEqualStrings("%{R}%{O16}%{B#deadbeef}Hello, World!%{B-}%{R}", str1);
    std.testing.expectEqualStrings("%{R}%{O16}%{B#deadbeef}Battery: 100%%%{B-}%{R}", str2);
}

test "unformat string" {
    var q1 = try unformat(std.testing.allocator, "%{F#ff0000}Hello%{F-}, %{R}World!%{R}");
    defer std.testing.allocator.free(q1);
    var q2 = try unformat(std.testing.allocator, "Battery: %{T1}100%{T-}%%");
    defer std.testing.allocator.free(q2);
    std.testing.expectEqualStrings("Hello, World!", q1);
    std.testing.expectEqualStrings("Battery: 100%", q2);
}
