const std = @import("std");
const ArrayList = std.ArrayList;

fn getPriority(ch: u8) u8 {
    if ('A' <= ch and ch <= 'Z') {
        return ch - 'A' + 27;
    }

    return ch - 'a' + 1;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var total_score_for_part_one: usize = 0;
    var total_score_for_part_two: usize = 0;

    const stdout = std.io.getStdOut().writer();

    var i: u32 = 0;
    var intersection = ArrayList(u8).init(gpa);
    defer intersection.deinit();
    var new_intersection = ArrayList(u8).init(gpa);
    defer new_intersection.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Part 1
        var first_half = line[0..line.len / 2];
        var second_half = line[line.len / 2..];
        for (first_half) |char| {
            if (std.mem.indexOfScalar(u8, second_half, char) != null) {
                total_score_for_part_one += getPriority(char);      
                break;  
            }
        }

        // Part 2
        if (i % 3 == 0) {
            if (i != 0) {
                var common_item_type = intersection.pop();
                total_score_for_part_two += getPriority(common_item_type);
            }
            intersection.clearRetainingCapacity();
            for (line) |char| {
                try intersection.append(char);
            }
        } else {
            new_intersection.clearRetainingCapacity();
            for (line) |char| {
                if (std.mem.indexOfScalar(u8, intersection.items, char) != null) {
                    try new_intersection.append(char);
                }
            }
            intersection = try new_intersection.clone();
        }

        i += 1;
    }

    // Additional iteration
    var common_item_type = intersection.pop();
    total_score_for_part_two += getPriority(common_item_type);

    try stdout.print("{}\n", .{total_score_for_part_one});
    try stdout.print("{}\n", .{total_score_for_part_two});
}
