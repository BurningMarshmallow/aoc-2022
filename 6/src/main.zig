const std = @import("std");

const input = @embedFile("input.txt");

pub fn main() !void {
    const N = 4;
    var end: usize = N;
    outer: while (end < input.len) : (end += 1) {
        const w = input[end - N .. end];
        for (w) |c, idx| {
            if (std.mem.indexOfScalar(u8, w[idx + 1 ..], c) != null) {
                continue :outer;
            }
        }
        break;
    }
    std.debug.print("{}\n", .{end});
}
