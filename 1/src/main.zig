const std = @import("std");

fn cmpByValueDesc(context: void, a: i32, b: i32) bool {
    return std.sort.desc(i32)(context, a, b);
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var buf: [1024]u8 = undefined;
    var total_calory: i32 = 0;

    var total_calories = std.ArrayList(i32).init(gpa);
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            try total_calories.append(total_calory);
            total_calory = 0;
        } else {
            var calory: i32 = try std.fmt.parseInt(i32, line, 10);
            total_calory += calory;
        }
    }
    try total_calories.append(total_calory);

    var total_calories_slice = total_calories.toOwnedSlice();
    std.sort.sort(i32, total_calories_slice, {}, cmpByValueDesc);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{total_calories_slice[0]});
    try stdout.print("{d}\n", .{total_calories_slice[0] + total_calories_slice[1] + total_calories_slice[2]});
}