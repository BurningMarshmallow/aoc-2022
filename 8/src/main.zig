const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const max = std.math.max;

const Int = i32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;
const N = 99;

const input = @embedFile("input.txt");

fn vis(trees: [N][N] Byte, i: usize, j: usize) bool {
    var t: usize = 0;
    while (t < i) : (t += 1) {
        if (trees[t][j] >= trees[i][j]) {
            break;
        }
    } else return true;

    t = i + 1;
    while (t < N) : (t += 1) {
        if (trees[t][j] >= trees[i][j]) {
            break;
        }
    } else return true;

    t = 0;
    while (t < j) : (t += 1) {
        if (trees[i][t] >= trees[i][j]) {
            break;
        }
    } else return true;

    t = j + 1;
    while (t < N) : (t += 1) {
        if (trees[i][t] >= trees[i][j]) {
            break;
        }
    } else return true;

    return false;
}

fn score(trees: [N][N] Byte, i: usize, j: usize) Ulong {
    var s1: Ulong = 0;
    var t: usize = 0;
    t = i;
    if (i != 0) {
        t = i - 1;
        while (t > 0) : (t -= 1) {
            s1 += 1;
            if (trees[t][j] >= trees[i][j]) {
                break;
            }
        }
    }
    if (t == 0) {
        s1 += 1;
    }

    var s2: Ulong = 0;
    t = i + 1;
    while (t < N) : (t += 1) {
        s2 += 1;
        if (trees[t][j] >= trees[i][j]) {
            break;
        }
    }

    var s3: Ulong = 0;
    t = j;
    if (j != 0) {
        t = j - 1;
        while (t > 0) : (t -= 1) {
            s3 += 1;
            if (trees[i][t] >= trees[i][j]) {
                break;
            }
        }
    }
    if (t == 0) {
        s3 += 1;
    }

    var s4: Ulong = 0;
    t = j + 1;
    while (t < N) : (t += 1) {
        s4 += 1;
        if (trees[i][t] >= trees[i][j]) {
            break;
        }
    }

    return s1 * s2 * s3 * s4;
}

pub fn main() !void {
    var trees = [1][N] Byte { [1]Byte{ 0 } ** N } ** N;
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var i: usize = 0;
    while (line_it.next()) |line| {
        var j: usize = 0;
        for (line) |tree| {
            trees[i][j] = tree - '0';
            j += 1;
        }
        i += 1;
    }

    var num_of_visible: Int = 0;
    var max_score: Ulong = 0;
    i = 0;
    while (i < N) : (i += 1) {
        var j: usize = 0;
        while (j < N) : (j += 1) {
            max_score = max(max_score, score(trees, i, j));
            if (vis(trees, i, j)) {
                num_of_visible += 1;
            }
        }
    }

    std.debug.print("{}\n", .{num_of_visible});
    std.debug.print("{}\n", .{max_score});
}
