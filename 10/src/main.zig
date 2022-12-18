const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const max = std.math.max;

const Int = i32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;

const input = @embedFile("input.txt");

fn parseNumber(string: String) !Int {
    return std.fmt.parseInt(Int, string, 10);
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var instructions = ArrayList(String).init(gpa);
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    while (line_it.next()) |line| {
        try instructions.append(line);
    }

    var display = ArrayList(String).init(gpa);
    var cycle: Int = 0;
    var register: Int = 1;
    var signal_strength: Int = 0;
    var cycles_to_add = [_]Int { 20, 60, 100, 140, 180, 220 };
    var row = ArrayList(Byte).init(gpa);

    for (instructions.items) |instruction| {
        var num_of_cycles: Int = if (instruction[0] == 'n') 1 else 2;
        var c: Int = 0;
        while (c < num_of_cycles) : (c += 1) {
            cycle += 1;
            if (register - 1 <= row.items.len and row.items.len <= register + 1) {
                try row.append('#');
            } else {
                try row.append('.');
            }
            if (row.items.len == 40) {
                var result_row = try row.clone();
                try display.append(result_row.items);
                row.clearRetainingCapacity();
            }
            if (std.mem.indexOfScalar(Int, &cycles_to_add, cycle) != null) {
                signal_strength += cycle * register;
            }   
        }

        if (instruction[0] == 'a') {
            var op_it = std.mem.tokenize(Byte, instruction, " ");
            _ = op_it.next();
            var value = op_it.next().?;
            register += try parseNumber(value);
        }
    }

    std.debug.print("{}\n", .{signal_strength});
    for (display.items) |r| {
        for (r) |char| {
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}
