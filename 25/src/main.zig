const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Int = u32;
const Byte = u8;
const SignedByte = i8;
const String = []const Byte;
const Long = i64;

const input = @embedFile("input.txt");

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

const SYMBOLS = "=-012";
fn toDigit(c: Byte) Long {
    return @intCast(Long, std.mem.indexOfScalar(Byte, SYMBOLS, c).?) - 2;
}

fn toSymbol(c: SignedByte) Byte {
    return SYMBOLS[@intCast(usize, c + 2)];
}

fn toLong(string: String) !Long {
    var num: Long = 0;
    var i: usize = 0;
    var n: usize = string.len;
    while (i < n) : (i += 1) {
        var c = string[i];
        var multiplier = toDigit(c);
        num += try std.math.powi(Long, 5, @intCast(Long, n - i - 1)) * multiplier;
    }
    return num;
}

fn toSnafu(value: Long, alloc: Allocator) !String {
    var snafuBytes = ArrayList(SignedByte).init(alloc);
    var prev_addition: Byte = 0;
    var addition: Byte = 0;
    var curr = value;
    while (curr > 0) {
        var mod = @mod(curr, 5);
        curr = @divFloor(curr, 5);
        mod += prev_addition;
        if (mod > 2) {
            addition = 1;
            mod -= 5;
        } else {
            addition = 0;
        }
        try snafuBytes.append(@intCast(SignedByte, mod));
        prev_addition = addition;
    }

    if (addition > 0) {
        try snafuBytes.append(@intCast(SignedByte, addition));
    }
    var snafuStr = ArrayList(Byte).init(alloc);
    std.mem.reverse(SignedByte, snafuBytes.items);
    for (snafuBytes.items) |byte| {
        try snafuStr.append(toSymbol(byte));
    }

    return snafuStr.items;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var result: Long = 0;
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    while (line_it.next()) |line| {
        result += try toLong(line);
    }

    print(result);
    printStr(try toSnafu(result, gpa));
}
