const std = @import("std");
const Color = @This();

alpha: ?u8 = null,
red: u8 = 0,
green: u8 = 0,
blue: u8 = 0,

pub fn write(this: Color, writer: anytype) !void {
    if (this.alpha) |a_value| {
        try writer.print("#{x:0>2}{x:0>2}{x:0>2}{x:0>2}", .{ this.alpha, this.red, this.green, this.blue });
    } else {
        try writer.print("#{x:0>2}{x:0>2}{x:0>2}", .{ this.red, this.green, this.blue });
    }
}

pub fn bufferWrite(this: Color, buffer: []u8) ![]const u8 {
    std.mem.set(u8, buffer, 0);
    if (this.alpha) |a_value| {
        if (buffer.len < 9) return error.OutOfSpace;
        return try std.fmt.bufPrint(buffer, "#{x:0>2}{x:0>2}{x:0>2}{x:0>2}", .{ this.alpha, this.red, this.green, this.blue });
    } else {
        if (buffer.len < 7) return error.OutOfSpace;
        return try std.fmt.bufPrint(buffer, "#{x:0>2}{x:0>2}{x:0>2}", .{ this.red, this.green, this.blue });
    }
}

pub fn toString(this: Color, allocator: *std.mem.Allocator) ![]u8 {
    if (this.alpha) |a_value| {
        return try std.fmt.allocPrint(allocator, "#{x:0>2}{x:0>2}{x:0>2}{x:0>2}", .{ this.alpha, this.red, this.green, this.blue });
    } else {
        return try std.fmt.allocPrint(allocator, "#{x:0>2}{x:0>2}{x:0>2}", .{ this.red, this.green, this.blue });
    }
}

pub fn fromString(string: []const u8) !Color {
    var alpha: ?u8 = null;
    var red: u8 = 0;
    var green: u8 = 0;
    var blue: u8 = 0;

    if (string.len > 0 and string[0] != '#') return error.InvalidInput;
    switch (string.len) {
        4 => {
            red = try std.fmt.charToDigit(string[1], 16);
            green = try std.fmt.charToDigit(string[2], 16);
            blue = try std.fmt.charToDigit(string[3], 16);
            red = red | std.math.shl(u8, red, 4);
            green = green | std.math.shl(u8, green, 4);
            blue = blue | std.math.shl(u8, blue, 4);
        },
        7 => {
            red = (try std.fmt.charToDigit(string[2], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[1], 16), 4);
            green = (try std.fmt.charToDigit(string[4], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[3], 16), 4);
            blue = (try std.fmt.charToDigit(string[6], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[5], 16), 4);
        },
        9 => {
            alpha = (try std.fmt.charToDigit(string[2], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[1], 16), 4);
            red = (try std.fmt.charToDigit(string[4], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[3], 16), 4);
            green = (try std.fmt.charToDigit(string[6], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[5], 16), 4);
            blue = (try std.fmt.charToDigit(string[8], 16)) | std.math.shl(u8, try std.fmt.charToDigit(string[7], 16), 4);
        },
        else => return error.InvalidInput,
    }

    return Color{
        .alpha = alpha,
        .red = red,
        .green = green,
        .blue = blue,
    };
}

test "write color string to buffer" {
    var buffer = [_]u8{0} ** 9;
    var color = Color{
        .alpha = 0xde,
        .red = 0xad,
        .green = 0xbe,
        .blue = 0xef,
    };
    std.testing.expectEqualStrings("#deadbeef", try color.bufferWrite(&buffer));

    color = Color{
        .alpha = null,
        .red = 0x06,
        .green = 0x94,
        .blue = 0x20,
    };
    std.testing.expectEqualStrings("#069420", try color.bufferWrite(&buffer));

    var buf2 = [_]u8{0} ** 4;
    std.testing.expectError(error.OutOfSpace, color.bufferWrite(&buf2));
}

test "color to string" {
    var color = Color{
        .alpha = 0xde,
        .red = 0xad,
        .green = 0xbe,
        .blue = 0xef,
    };
    var string_1 = try color.toString(std.testing.allocator);
    defer std.testing.allocator.free(string_1);
    std.testing.expectEqualStrings("#deadbeef", string_1);

    color = Color{
        .alpha = null,
        .red = 0x06,
        .green = 0x94,
        .blue = 0x20,
    };
    var string_2 = try color.toString(std.testing.allocator);
    defer std.testing.allocator.free(string_2);
    std.testing.expectEqualStrings("#069420", string_2);
}

test "color from string" {
    std.testing.expectEqual(Color{
        .alpha = null,
        .red = 0xaa,
        .green = 0xbb,
        .blue = 0xcc,
    }, try Color.fromString("#abc"));
    std.testing.expectEqual(Color{
        .alpha = null,
        .red = 0x06,
        .green = 0x94,
        .blue = 0x20,
    }, try Color.fromString("#069420"));
    std.testing.expectEqual(Color{
        .alpha = 0xde,
        .red = 0xad,
        .green = 0xbe,
        .blue = 0xef,
    }, try Color.fromString("#deadbeef"));

    std.testing.expectError(error.InvalidInput, Color.fromString("#0000000"));
    std.testing.expectError(error.InvalidInput, Color.fromString("000000"));
}

test "lossless conversion to/from string" {
    var string_1 = "#069420";
    var string_2 = "#deadbeef";
    var buffer = [_]u8{0} ** 9;
    std.testing.expectEqualStrings(string_1, try (try Color.fromString(string_1)).bufferWrite(&buffer));
    std.testing.expectEqualStrings(string_2, try (try Color.fromString(string_2)).bufferWrite(&buffer));
}
