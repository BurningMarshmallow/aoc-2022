const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const min = std.math.min;
const max = std.math.max;

const Int = i32;
const Byte = u8;
const String = []const Byte;

const V = struct {
    x: Int,
    y: Int,
    fn plus(self: *V, other: V) V {
        return V{ .x = self.x + other.x, .y = self.y + other.y };
    }
};

test "Plus" {
    var first = V{ .x = 10, .y = 20 };
    var second = V{ .x = 30, .y = 50 };
    
    var value = first.plus(second);
    try std.testing.expect(value.x == 40 and value.y == 70);
}


const Seg = struct {
    start: V,
    end: V,
    fn contains(self: *const Seg, value: V) bool {
        return min(self.start.x, self.end.x) <= value.x and value.x <= max(self.start.x, self.end.x) and 
               min(self.start.y, self.end.y) <= value.y and value.y <= max(self.start.y, self.end.y);
    }
};

test "Contains" {
    var seg = Seg{ .start = V{ .x = 10, .y = 20 }, .end = V{ .x = 30, .y = 50 } };
    var value = V{ .x = 20, .y = 40 };
    
    try std.testing.expect(seg.contains(value) == true);
}

fn parseNumber(string: String) !Int {
    return std.fmt.parseInt(Int, string, 10);
}

fn parseV(string: String) !V {
    var coordsIt = std.mem.tokenize(Byte, string, ",");
    return V{ .x = try parseNumber(coordsIt.next().?), .y = try parseNumber(coordsIt.next().?) };
}

fn containsInCave(cave: ArrayList(Seg), value: V) bool {
    for (cave.items) |seg| {
        if (seg.contains(value)) {
            return true;
        }
    }
    return false;
}

fn hitTheBottom(threshold: Int, bottom: V) bool {
    return bottom.y == threshold + 2;
}

fn numOfEntries(map: std.AutoHashMap(V, void)) Int {
    var it = map.iterator();
    var num_of_entries: Int = 0;
    while (it.next()) |_| {
        num_of_entries += 1;
    }

    return num_of_entries;
}

const input = @embedFile("input.txt");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var cave = ArrayList(Seg).init(gpa);
    defer cave.deinit();

    var lineIt = std.mem.tokenize(Byte, input, "\n");
    while (lineIt.next()) |line| {
        var pointsIt = std.mem.tokenize(Byte, line, " -> ");
        var start = try parseV(pointsIt.next().?);
        while (pointsIt.next()) |pointStr| {
            var end = try parseV(pointStr);
            var seg = Seg{ .start = start, .end = end };
            try cave.append(seg);
            start = end;
        }
    }

    var sand_source = V { .x = 500, .y = 0 };
    var sand = std.AutoHashMap(V, void).init(gpa);
    defer sand.deinit();

    var threshold: Int = 165; // by hand
    while (true) {
        var new_grain = sand_source;
        while (true) {
            if (threshold < new_grain.y) {
                break;
            }

            var bottom = new_grain.plus(V { .x = 0, .y = 1} );
            if (!containsInCave(cave, bottom) and !sand.contains(bottom)) {
                new_grain = bottom;
                continue;
            }
            var bottom_left = new_grain.plus(V { .x = -1, .y = 1} );
            if (!containsInCave(cave, bottom_left) and !sand.contains(bottom_left)) {
                new_grain = bottom_left;
                continue;
            }
            var bottom_right = new_grain.plus(V { .x = 1, .y = 1} );
            if (!containsInCave(cave, bottom_right) and !sand.contains(bottom_right)) {
                new_grain = bottom_right;
                continue;
            }
            break;
        }
        
        if (threshold < new_grain.y) {
            break;
        }
        try sand.put(new_grain, {});
    }

    // Part 2
    std.debug.print("Part 2 begins\n", .{});
    var moresand = std.AutoHashMap(V, void).init(gpa);
    defer moresand.deinit();

    var i: Int = 0;
    while (true) {
        i += 1;
        if (@mod(i, 1000) == 0) {
            std.debug.print("{}\n", .{i});
        }
        var new_grain = sand_source;
        while (true) {
            var bottom = new_grain.plus(V { .x = 0, .y = 1} );
            if (!containsInCave(cave, bottom) and !moresand.contains(bottom) and !hitTheBottom(threshold, bottom)) {
                new_grain = bottom;
                continue;
            }
            var bottom_left = new_grain.plus(V { .x = -1, .y = 1} );
            if (!containsInCave(cave, bottom_left) and !moresand.contains(bottom_left) and !hitTheBottom(threshold, bottom)) {
                new_grain = bottom_left;
                continue;
            }
            var bottom_right = new_grain.plus(V { .x = 1, .y = 1} );
            if (!containsInCave(cave, bottom_right) and !moresand.contains(bottom_right) and !hitTheBottom(threshold, bottom)) {
                new_grain = bottom_right;
                continue;
            }
            break;
        }

        try moresand.put(new_grain, {});
        if (new_grain.x == sand_source.x and new_grain.y == sand_source.y) {
            break;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{numOfEntries(sand)});
    try stdout.print("Part 2: {}\n", .{numOfEntries(moresand)});
}
