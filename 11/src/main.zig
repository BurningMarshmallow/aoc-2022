const std = @import("std");
const regex = @import("regex");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const max = std.math.max;

const Int = u32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;

const input = @embedFile("input.txt");

fn parseNumber(string: String) !Int {
    return std.fmt.parseInt(Int, string, 10);
}

fn parseLongNumber(string: String) !Ulong {
    return std.fmt.parseInt(Ulong, string, 10);
}

const Monkey = struct {
    items: ArrayList(Ulong),
    operation_str: String,
    operand_str: String,
    test_value: Ulong,
    pos_value: Ulong,
    neg_value: Ulong,
    fn init(items: ArrayList(Ulong), operation_str: String, operand_str: String, test_value: Ulong, pos_value: Ulong, neg_value: Ulong) Monkey {
        return Monkey{ .items = items, .operation_str = operation_str, .operand_str = operand_str, .test_value = test_value, .pos_value = pos_value, .neg_value = neg_value };
    }
    fn clearItems(self: *Monkey) void {
        self.items.clearRetainingCapacity();
    }
};

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

fn part1(alloc: Allocator, monkeys: ArrayList(Monkey)) !void {
    var inspections = std.AutoHashMap(Int, Ulong).init(alloc);
    var num_of_rounds: Int = 0;
    while (num_of_rounds < 20) : (num_of_rounds += 1) {
        for (monkeys.items) |monkey, i| {
            for (monkey.items.items) |item| {
                var idx = @intCast(Int, i);
                if (inspections.contains(idx)) {
                    try inspections.put(idx, inspections.get(idx).? + 1);
                } else {
                    try inspections.put(idx, 1);
                }
                var new: Ulong = 0;
                if (std.mem.eql(Byte, monkey.operand_str, "old")) {
                    new = item * item;
                } else {
                    if (std.mem.eql(Byte, monkey.operation_str, "+")) {
                        new = item + try parseNumber(monkey.operand_str);
                    } else {
                        new = item * try parseNumber(monkey.operand_str);
                    }
                }
                
                new = @divFloor(new, 3);
                if (@mod(new, monkey.test_value) == 0) {
                    try monkeys.items[@intCast(usize, monkey.pos_value)].items.append(new);
                } else {
                    try monkeys.items[@intCast(usize, monkey.neg_value)].items.append(new);
                }
            }

            monkeys.items[i].clearItems();
        }
    }

    var it = inspections.valueIterator();
    var m1: Ulong = 0;
    var m2: Ulong = 0;
    while (it.next()) |inspection| {
        var value: Ulong = inspection.*;
        if (value > m1) {
            m2 = m1;
            m1 = value;
        } else {
            if (value > m2) {
                m2 = value;
            }
        }
    }
    print(m1 * m2);
}

fn part2(alloc: Allocator, monkeys: ArrayList(Monkey)) !void {
    var inspections = std.AutoHashMap(Int, Ulong).init(alloc);
    var num_of_rounds: Int = 0;
    while (num_of_rounds < 10000) : (num_of_rounds += 1) {
        for (monkeys.items) |monkey, i| {
            for (monkey.items.items) |item| {
                var idx = @intCast(Int, i);
                if (inspections.contains(idx)) {
                    try inspections.put(idx, inspections.get(idx).? + 1);
                } else {
                    try inspections.put(idx, 1);
                }
                var new: Ulong = 0;
                if (std.mem.eql(Byte, monkey.operand_str, "old")) {
                    new = @intCast(Ulong, item) * @intCast(Ulong, item);
                } else {
                    if (std.mem.eql(Byte, monkey.operation_str, "+")) {
                        new = item + try parseNumber(monkey.operand_str);
                    } else {
                        new = item * try parseNumber(monkey.operand_str);
                    }
                }
                
                new = @mod(new, 9699690);
                if (@mod(new, monkey.test_value) == 0) {
                    try monkeys.items[@intCast(usize, monkey.pos_value)].items.append(new);
                } else {
                    try monkeys.items[@intCast(usize, monkey.neg_value)].items.append(new);
                }
            }

            monkeys.items[i].clearItems();
        }
    }

    var it = inspections.valueIterator();
    var m1: Ulong = 0;
    var m2: Ulong = 0;
    while (it.next()) |inspection| {
        var value: Ulong = inspection.*;
        if (value > m1) {
            m2 = m1;
            m1 = value;
        } else {
            if (value > m2) {
                m2 = value;
            }
        }
    }
    print(m1 * m2);
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var monkeys_for_part_one = ArrayList(Monkey).init(gpa);
    var monkeys_for_part_two = ArrayList(Monkey).init(gpa);
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var item_pattern = try regex.Regex.compile(gpa, ".*Starting items: (.*)");
    var op_pattern = try regex.Regex.compile(gpa, ".*Operation: new = old (.*) (.*)");
    var test_pattern = try regex.Regex.compile(gpa, ".*Test: divisible by (.*)");
    var pos_pattern = try regex.Regex.compile(gpa, ".*monkey (.*)");
    var neg_pattern = try regex.Regex.compile(gpa, ".*monkey (.*)");

    while (line_it.next()) |_| {
        var item_captures = (try item_pattern.captures(line_it.next().?)).?;
        var items_str = item_captures.sliceAt(1).?;
        var items = ArrayList(Ulong).init(gpa);
        var item_it = std.mem.tokenize(Byte, items_str, ", ");
        while (item_it.next()) |item| {
            try items.append(try parseLongNumber(item));
        }

        var op_captures = (try op_pattern.captures(line_it.next().?)).?;
        var operation_str = op_captures.sliceAt(1).?;
        var operand_str = op_captures.sliceAt(2).?;

        var test_captures = (try test_pattern.captures(line_it.next().?)).?;
        var test_str = test_captures.sliceAt(1).?;
        var test_value = try parseLongNumber(test_str);

        var pos_captures = (try pos_pattern.captures(line_it.next().?)).?;
        var pos_str = pos_captures.sliceAt(1).?;
        var pos_value = try parseLongNumber(pos_str);

        var neg_captures = (try neg_pattern.captures(line_it.next().?)).?;
        var neg_str = neg_captures.sliceAt(1).?;
        var neg_value = try parseLongNumber(neg_str);

        var items_for_part_two = try items.clone();
        try monkeys_for_part_one.append(Monkey.init(items, operation_str, operand_str, test_value, pos_value, neg_value));
        try monkeys_for_part_two.append(Monkey.init(items_for_part_two, operation_str, operand_str, test_value, pos_value, neg_value));
    }

    try part1(gpa, monkeys_for_part_one);
    try part2(gpa, monkeys_for_part_two);
}
