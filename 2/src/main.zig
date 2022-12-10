const std = @import("std");

const N = 10;
fn indexOf(haystack: [N][]const u8, needle: []u8) usize {
    for (haystack) |value, index| {
        if (std.mem.eql(u8, value, needle)) {
            return index;
        }
    }

    unreachable;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var total_score_for_part_one: usize = 0;
    var total_score_for_part_two: usize = 0;

    // Precalculated score for each combination
    var scores_for_part_one = [N][]const u8{ "", "B X", "C Y", "A Z", "A X", "B Y", "C Z", "C X", "A Y", "B Z" };
    var scores_for_part_two = [N][]const u8{ "", "B X", "C X", "A X", "A Y", "B Y", "C Y", "C Z", "A Z", "B Z" };
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        total_score_for_part_one += indexOf(scores_for_part_one, line);
        total_score_for_part_two += indexOf(scores_for_part_two, line);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{total_score_for_part_one});
    try stdout.print("{d}\n", .{total_score_for_part_two});
}
