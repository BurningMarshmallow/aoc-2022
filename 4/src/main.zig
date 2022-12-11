const std = @import("std");
const regex = @import("regex");

fn parseNumber(string: []const u8) !u16 {
    return try std.fmt.parseInt(u16, string, 10);
}

const input = @embedFile("input.txt");
pub fn main() !void {
    var total_score_for_part_one: usize = 0;
    var total_score_for_part_two: usize = 0;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var pattern = try regex.Regex.compile(gpa, "(\\d+)-(\\d+),(\\d+)-(\\d+)");
    defer pattern.deinit();

    var it = std.mem.tokenize(u8, input, "\n");
    while (it.next()) |line| {
        var captures = (try pattern.captures(line)).?;
        var a = try parseNumber(captures.sliceAt(1).?);
        var b = try parseNumber(captures.sliceAt(2).?);
        var c = try parseNumber(captures.sliceAt(3).?);
        var d = try parseNumber(captures.sliceAt(4).?);

        if (a <= c and d <= b or c <= a and b <= d) {
            total_score_for_part_one += 1;
        }

        if (c <= b and b <= d or a <= d and d <= b) {
            total_score_for_part_two += 1;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}\n", .{total_score_for_part_one});
    try stdout.print("{}\n", .{total_score_for_part_two});
}
