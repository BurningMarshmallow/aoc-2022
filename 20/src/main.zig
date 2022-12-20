const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const min = std.math.min;
const max = std.math.max;
const indexOf = std.mem.indexOfScalar;

const Long = i64;
const Byte = u8;
const String = []const Byte;

fn parseNumber(string: String) !Long {
    return std.fmt.parseInt(Long, string, 10);
}

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

fn toLong(value: usize) Long {
    return @intCast(Long, value);
}

const input = @embedFile("input.txt");

fn part1(numbers: ArrayList(Long), alloc: Allocator) !void {
    var indices = ArrayList(usize).init(alloc);
    var n = numbers.items.len;
    var index: usize = 0;
    while (index < n) : (index += 1) {
        try indices.append(index);
    }

    for (numbers.items) |num, i| {
        var location = indexOf(usize, indices.items, i).?;
        _ = indices.orderedRemove(location);
        var insertionIndex = @mod(toLong(location) + num, toLong(n - 1));
        if (insertionIndex == 0) {
            try indices.append(i);
        } else {
            try indices.insert(@intCast(usize, insertionIndex), i);
        }
    }

    var zero_index_in_numbers = indexOf(Long, numbers.items, 0).?;
    var zero_index = indexOf(usize, indices.items, zero_index_in_numbers).?;
	var a = numbers.items[indices.items[(zero_index+1000)%n]];
	var b = numbers.items[indices.items[(zero_index+2000)%n]];
	var c = numbers.items[indices.items[(zero_index+3000)%n]];

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{a+b+c});
}

fn part2(numbers: ArrayList(Long), alloc: Allocator) !void {
    var decrypted_numbers = ArrayList(Long).init(alloc);
    for (numbers.items) |number| {
        try decrypted_numbers.append(number * 811589153);
    }

    var indices = ArrayList(usize).init(alloc);
    var n = decrypted_numbers.items.len;
    var index: usize = 0;
    while (index < n) : (index += 1) {
        try indices.append(index);
    }

    var num_of_rounds: usize = 0;
    while (num_of_rounds < 10) : (num_of_rounds += 1) {
        for (decrypted_numbers.items) |num, i| {
            var location = indexOf(usize, indices.items, i).?;
            _ = indices.orderedRemove(location);
            var insertionIndex = @mod(toLong(location) + num, toLong(n - 1));
            if (insertionIndex == 0) {
                try indices.append(i);
            } else {
                try indices.insert(@intCast(usize, insertionIndex), i);
            }
        }
    }

    var zero_index_in_numbers = indexOf(Long, decrypted_numbers.items, 0).?;
    var zero_index = indexOf(usize, indices.items, zero_index_in_numbers).?;
	var a = decrypted_numbers.items[indices.items[(zero_index+1000)%n]];
	var b = decrypted_numbers.items[indices.items[(zero_index+2000)%n]];
	var c = decrypted_numbers.items[indices.items[(zero_index+3000)%n]];

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 2: {}\n", .{a+b+c});
}


pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var numbers = ArrayList(Long).init(gpa);
    
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    while (line_it.next()) |line| {
        try numbers.append(try parseNumber(line));
    }

    try part1(numbers, gpa);
    try part2(numbers, gpa);
}
