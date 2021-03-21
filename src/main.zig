const std = @import("std");

const Formatter = @import("./Formatter.zig");
const FormatterProperty = Formatter.FormatterProperty;

pub fn main() anyerror!void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(!gp.deinit());
    const alloc = &gp.allocator;

    std.log.info("All your codebase are belong to us.", .{});
}

test "_" {
    _ = @import("./Formatter.zig");
}
