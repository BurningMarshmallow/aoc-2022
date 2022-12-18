const std = @import("std");
const Queue = @import("queue").Queue;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const min = std.math.min;
const max = std.math.max;

const Int = i32;
const Byte = u8;
const String = []const Byte;

const CubeSet = std.AutoHashMap(V3, void);

const V3 = struct {
    x: Int,
    y: Int,
    z: Int,
    fn plus(self: *V3, other: V3) V3 {
        return V3{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    fn init(x: Int, y: Int, z: Int) V3 {
        return V3{ .x = x, .y = y, .z = z };
    }
};

fn parseNumber(string: String) !Int {
    return std.fmt.parseInt(Int, string, 10);
}

fn inArea(value: Int, l: Int, r: Int) bool {
    return l <= value and value <= r;
}

const input = @embedFile("input.txt");

fn part1(points: CubeSet) !void {
    var surface_area: Int = 0;

    var it = points.keyIterator();
    var offsets = [_]V3 { V3.init(-1, 0, 0), V3.init(1, 0, 0), V3.init(0, -1, 0), V3.init(0, 1, 0), V3.init(0, 0, -1), V3.init(0, 0, 1) };
    while (it.next()) |v| {
        for (offsets) |offset| {
            var n = v.plus(offset);
            if (!points.contains(n)) {
                surface_area += 1;
            }
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{surface_area});
}

fn part2(alloc: Allocator, points: CubeSet) !void {
    var surface_area: Int = 0;
    var left: Int = -1;
    var right: Int = 21;
    var offsets = [_]V3 { V3.init(-1, 0, 0), V3.init(1, 0, 0), V3.init(0, -1, 0), V3.init(0, 1, 0), V3.init(0, 0, -1), V3.init(0, 0, 1) };

    var steam = CubeSet.init(alloc);
    defer steam.deinit();
    try steam.put(V3.init(0, 0, 0), {});
    var q = Queue(V3).init(alloc);
    try q.enqueue(V3.init(0, 0, 0));
    while (!q.empty()) {
        var v = q.dequeue().?;
        for (offsets) |offset| {
            var n = v.plus(offset);
            if (!inArea(n.x, left, right) or !inArea(n.y, left, right) or !inArea(n.z, left, right)) {
                continue;
            }
            if (points.contains(n)) {
                surface_area += 1;
            } else {
                if (!steam.contains(n)) {
                    try steam.put(n, {});
                    try q.enqueue(n);
                }
            }
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 2: {}\n", .{surface_area});
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var points = CubeSet.init(gpa);
    defer points.deinit();

    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    while (line_it.next()) |line| {
        var points_it = std.mem.tokenize(Byte, line, ",");
        var point = V3{ .x = try parseNumber(points_it.next().?), .y = try parseNumber(points_it.next().?), .z = try parseNumber(points_it.next().?) };
        try points.put(point, {});
    }

    try part1(points);
    try part2(gpa, points);
}
