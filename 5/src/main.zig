const std = @import("std");
const regex = @import("regex");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

fn parseNumber(string: []const u8) !u16 {
    return try std.fmt.parseInt(u16, string, 10);
}

fn addString(listOfLists: *ArrayList(ArrayList(u8)), string: []const u8, allocator: Allocator) !void {
    var list = ArrayList(u8).init(allocator);
    try list.appendSlice(string);
    try listOfLists.*.append(list);
}

fn initWithRealInput(listOfLists: *ArrayList(ArrayList(u8)), allocator: Allocator) !void {
    try addString(listOfLists, "LNWTD", allocator);
    try addString(listOfLists, "CPH", allocator);
    try addString(listOfLists, "WPHNDGMJ", allocator);
    try addString(listOfLists, "CWSNTQL", allocator);
    try addString(listOfLists, "PHCN", allocator);
    try addString(listOfLists, "THNDMWQB", allocator);
    try addString(listOfLists, "MBRJGSL", allocator);
    try addString(listOfLists, "ZNWGVBRT", allocator);
    try addString(listOfLists, "WGDNPL", allocator);
}

const input = @embedFile("input.txt");
pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var pattern = try regex.Regex.compile(gpa, "move (\\d+) from (\\d+) to (\\d+)");
    defer pattern.deinit();

    var it = std.mem.split(u8, input, "\n");
    
    // Skip parsing crates, easier to hardcode
    while (it.next()) |line| {
        if (line.len == 0) {
            break;
        }
    }

    // Init to avoid parsing
    var stacks_for_part_one = ArrayList(ArrayList(u8)).init(gpa);   
    defer stacks_for_part_one.deinit();
    try initWithRealInput(&stacks_for_part_one, gpa);

    var stacks_for_part_two = ArrayList(ArrayList(u8)).init(gpa);   
    defer stacks_for_part_two.deinit();
    try initWithRealInput(&stacks_for_part_two, gpa);

    while (it.next()) |line| {
        var captures = (try pattern.captures(line)).?;
        var a = try parseNumber(captures.sliceAt(1).?);
        var b = try parseNumber(captures.sliceAt(2).?);
        var c = try parseNumber(captures.sliceAt(3).?);

        // Part 1
        var i: u16 = 0;
        while (i < a) : (i += 1) {
            var to_move = stacks_for_part_one.items[b - 1].pop();
            try stacks_for_part_one.items[c - 1].append(to_move);
        }

        // Part 2
        i = 0;
        var tmp = ArrayList(u8).init(gpa);
        defer tmp.deinit();
        while (i < a) : (i += 1) {
            var to_move = stacks_for_part_two.items[b - 1].pop();
            try tmp.append(to_move);
        }

        std.mem.reverse(u8, tmp.items);
        for (tmp.items) |item| {
            try stacks_for_part_two.items[c - 1].append(item);
        }
    }

    const stdout = std.io.getStdOut().writer();
    for (stacks_for_part_one.items) |value| {
        try stdout.print("{c}", .{value.items[value.items.len - 1]});
    }
    try stdout.print("\n", .{});

    for (stacks_for_part_two.items) |value| {
        try stdout.print("{c}", .{value.items[value.items.len - 1]});
    }
    try stdout.print("\n", .{});
}
