const std = @import("std");
const regex = @import("regex");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Complex = std.math.complex.Complex;

const eql = std.mem.eql;

const Byte = u8;
const Float = f32;
const String = []const Byte;
const Ulong = u64;

fn parseNumber(string: String) !Ulong {
    return std.fmt.parseInt(Ulong, string, 10);
}

fn sign(value: Float) Float {
    if (value > 0) 
        return 1;
    if (value < 0)
        return -1;
    return 0;
}

fn signComplex(value: Complex(Float)) Complex(Float) {
    var re = sign(value.re);
    var im = sign(value.im);
    return Complex(Float).init(re, im);
}

fn contains(haystack: []const Complex(Float), needle: Complex(Float)) bool {
    for (haystack) |value| {
        if (value.re == needle.re and value.im == needle.im) {
            return true;
        }
    }

    return false;
}

const input = @embedFile("input.txt");
pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    
    var pattern = try regex.Regex.compile(gpa, "(.*) (\\d+)");
    defer pattern.deinit();

    var rope = [_]Complex(Float) { Complex(Float).init(0, 0) } ** 10;
    var dirs = std.StringHashMap(Complex(Float)).init(gpa);
    try dirs.put("L", Complex(Float).init(1, 0));
    try dirs.put("R", Complex(Float).init(-1, 0));
    try dirs.put("D", Complex(Float).init(0, 1));
    try dirs.put("U", Complex(Float).init(0, -1));
    var seen = std.AutoHashMap(usize, ArrayList(Complex(Float))).init(gpa);
    var t: usize = 0;
    while (t < 10) : (t += 1) {
        var init = ArrayList(Complex(Float)).init(gpa);
        try init.append(Complex(Float).init(0, 0));
        try seen.put(t, init);
    }

    var it = std.mem.tokenize(Byte, input, "\n");
    while (it.next()) |line| {
        if (try pattern.match(line)) {
            var captures = (try pattern.captures(line)).?;
            var dir = captures.sliceAt(1).?;
            var n = try parseNumber(captures.sliceAt(2).?);

            var i: usize = 0;
            while (i < n) : (i += 1) {
                var offset = dirs.get(dir).?;
                rope[0] = rope[0].add(offset);

                var j: usize = 1;
                while (j < 10) : (j += 1) {
                    var dist = rope[j-1].sub(rope[j]);
                    if (dist.magnitude() >= 2) {
                        rope[j] = rope[j].add(signComplex(dist));
                        var value = seen.get(j).?;
                        if (!contains(value.items, rope[j])) {
                            try value.append(rope[j]);
                            try seen.put(j, value);                        
                        }
                    }
                }
            }
        } else {
            @panic("Line was not in correct format");
        }
    }

    var answer_for_part_one = seen.get(1).?.items.len;
    var answer_for_part_two = seen.get(9).?.items.len;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}\n", .{answer_for_part_one});
    try stdout.print("{}\n", .{answer_for_part_two});
}

test "sign" {
    try std.testing.expect(sign(1) == 1);
    try std.testing.expect(sign(0) == 0);
    try std.testing.expect(sign(-3) == -1);

    var value = Complex(Float).init(1, -1);
    try std.testing.expect(signComplex(value).im == -1);
}