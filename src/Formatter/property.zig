const std = @import("std");

pub const Alignment = enum { left, right, center };
pub const Button = struct {
    command: []const u8,
    button: ?u8,
};
pub const Monitor = union(enum) {
    next,
    previous,
    first,
    last,
    nth: u8,
};
pub const AttrModifier = struct {
    pub const Attribute = enum { overline, underline };
    pub const Modifier = enum { set, unset, toggle };
    attribute: Attribute,
    modifier: Modifier,
};
pub const Color = @import("Color.zig");

pub const Property = union(enum) {
    swap: void,
    alignment: Alignment,
    offset: u16,
    background: ?Color,
    foreground: ?Color,
    font: ?u8,
    underline: ?Color,
    click: ?Button,
    monitor: Monitor,
    attrmod: AttrModifier,

    pub fn close(prop: Property) ?Property {
        return switch (prop) {
            .swap => .swap,
            .background => .{ .background = null },
            .foreground => .{ .foreground = null },
            .font => .{ .font = null },
            .underline => .{ .underline = null },
            .click => .{ .click = null },
            .attrmod => |l| .{ .attrmod = AttrModifier{ .attribute = l.attribute, .modifier = .unset } },
            else => null,
        };
    }

    pub fn toString(this: Property, allocator: *std.mem.Allocator) ![]const u8 {
        var str = std.ArrayList(u8).init(allocator);
        _ = try this.write(str.writer());
        return str.toOwnedSlice();
    }

    pub fn write(this: Property, writer: anytype) !void {
        _ = try writer.write("%{");

        switch (this) {
            .swap => {
                _ = try writer.write("R");
            },
            .alignment => |align_value| {
                _ = try writer.write(switch (align_value) {
                    .left => "l",
                    .right => "r",
                    .center => "c",
                });
            },
            .offset => |offset_value| {
                _ = try writer.print("O{}", .{offset_value});
            },
            .background => |bg_color| {
                _ = try writer.write("B");
                if (bg_color) |color| {
                    _ = try color.write(&writer);
                } else {
                    _ = try writer.write("-");
                }
            },
            .foreground => |fg_color| {
                _ = try writer.write("F");
                if (fg_color) |color| {
                    _ = try color.write(&writer);
                } else {
                    _ = try writer.write("-");
                }
            },
            .font => |font_index| {
                if (font_index) |idx| {
                    _ = try writer.print("T{}", .{font_index});
                } else {
                    _ = try writer.write("T-");
                }
            },
            .underline => |ul_color| {
                _ = try writer.write("U");
                if (ul_color) |color| {
                    _ = try color.write(&writer);
                } else {
                    _ = try writer.write("-");
                }
            },
            .click => |btn_struct| {
                if (btn_struct) |btn| {
                    if (btn.button) |button| {
                        _ = try writer.print("A{}:{s}:", .{ button, btn.command });
                    } else {
                        _ = try writer.print("A:{s}:", .{btn.command});
                    }
                }
            },
            .monitor => |monitor_value| {
                _ = try writer.write("S");
                switch (monitor_value) {
                    .next => {
                        _ = try writer.write("+");
                    },
                    .previous => {
                        _ = try writer.write("-");
                    },
                    .first => {
                        _ = try writer.write("f");
                    },
                    .last => {
                        _ = try writer.write("l");
                    },
                    .nth => |monitor_index| {
                        _ = try writer.print("{}", .{monitor_index});
                    },
                }
            },
            .attrmod => |attr_struct| {
                _ = try writer.write(switch (attr_struct.modifier) {
                    .set => "+",
                    .unset => "-",
                    .toggle => "!",
                });
                _ = try writer.write(switch (attr_struct.attribute) {
                    .overline => "o",
                    .underline => "u",
                });
            },
        }

        _ = try writer.write("}");
    }
};

// TESTS //
fn expectProperty(expected: []const u8, prop: Property) void {
    var str = prop.toString(std.testing.allocator) catch unreachable;
    defer std.testing.allocator.free(str);
    std.testing.expectEqualStrings(expected, str);
}

test "property to string" {
    expectProperty("%{R}", .swap);
    expectProperty("%{l}", .{ .alignment = .left });
    expectProperty("%{c}", .{ .alignment = .center });
    expectProperty("%{r}", .{ .alignment = .right });
    expectProperty("%{O16}", .{ .offset = 16 });
    expectProperty("%{B#deadbeef}", .{ .background = comptime try Color.fromString("#deadbeef") });
    expectProperty("%{B-}", .{ .background = null });
    expectProperty("%{F#deadbeef}", .{ .foreground = comptime try Color.fromString("#deadbeef") });
    expectProperty("%{F-}", .{ .foreground = null });
    expectProperty("%{T1}", .{ .font = 1 });
    expectProperty("%{T-}", .{ .font = null });
    expectProperty("%{U#deadbeef}", .{ .underline = comptime try Color.fromString("#deadbeef") });
    expectProperty("%{U-}", .{ .underline = null });
    expectProperty("%{A:reboot:}", .{ .click = .{ .button = null, .command = "reboot" } });
    expectProperty("%{A3:halt:}", .{ .click = .{ .button = 3, .command = "halt" } });
    expectProperty("%{S+}", .{ .monitor = .next });
    expectProperty("%{S-}", .{ .monitor = .previous });
    expectProperty("%{Sf}", .{ .monitor = .first });
    expectProperty("%{Sl}", .{ .monitor = .last });
    expectProperty("%{S5}", .{ .monitor = .{ .nth = 5 } });
    expectProperty("%{+o}", .{ .attrmod = .{ .attribute = .overline, .modifier = .set } });
    expectProperty("%{-o}", .{ .attrmod = .{ .attribute = .overline, .modifier = .unset } });
    expectProperty("%{!o}", .{ .attrmod = .{ .attribute = .overline, .modifier = .toggle } });
    expectProperty("%{+u}", .{ .attrmod = .{ .attribute = .underline, .modifier = .set } });
    expectProperty("%{-u}", .{ .attrmod = .{ .attribute = .underline, .modifier = .unset } });
    expectProperty("%{!u}", .{ .attrmod = .{ .attribute = .underline, .modifier = .toggle } });
}
