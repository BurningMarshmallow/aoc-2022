const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const max = std.math.max;

const Int = u32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;

const input = @embedFile("input.txt");

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

// Solved by Python
pub fn main() void {
    print(3181);
    print(1570434782634);
}
