const std = @import("std");
const regex = @import("regex");
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

fn abs(a: Int) Int
{
	return if (a > 0) a else -a;
}

const DevicePair = struct {
    sensor: V,
    beacon: V,
    fn init(sensor: V, beacon: V) DevicePair {
        return DevicePair{ .sensor = sensor, .beacon = beacon };
    }
};

const V = struct {
    x: Int,
    y: Int,
    fn plus(self: *V, other: V) V {
        return V{ .x = self.x + other.x, .y = self.y + other.y };
    }
    fn minus(self: *const V, other: V) V {
        return V{ .x = self.x - other.x, .y = self.y - other.y };
    }
    fn init(x: Int, y: Int) V {
        return V{ .x = x, .y = y };
    }
    fn dist(self: *const V) Int {
        return abs(self.x) + abs(self.y);
    }
};

const Seg = struct {
    start: Int,
    end: Int,
    fn contains(self: *const Seg, value: Int) bool {
        return self.start <= value and value <= self.end;
    }
    fn init(left: Int, right: Int) Seg {
        return Seg{ .start = left, .end = right };
    }
};

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

fn cmpByX(context: void, a: Seg, b: Seg) bool {
    return std.sort.asc(Int)(context, a.start, b.start);
}

fn contains(list: ArrayList(V), value: V) bool {
    for (list.items) |item| {
        if (item.x == value.x and item.y == value.y) {
            return true;
        }
    }
    return false;
}

fn getSegments(alloc: Allocator, input_values: ArrayList(DevicePair), y: Int) !ArrayList(Seg) {
    var result = ArrayList(Seg).init(alloc);
    for (input_values.items) |device_pair| {
        var max_d = (device_pair.sensor.minus(device_pair.beacon)).dist();
        var d = abs(y - device_pair.sensor.y);
        if (d < max_d) {
            var delta = max_d - d;
            try result.append(Seg.init(device_pair.sensor.x - delta, device_pair.sensor.x + delta));
        }
    }

    std.sort.sort(Seg, result.items[0..], {}, cmpByX);
    return result;
}

fn part1(alloc: Allocator, input_values: ArrayList(DevicePair), beacons: ArrayList(V)) !void {
    var target_y: Int = 2_000_000;
    var segments = try getSegments(alloc, input_values, target_y);
    defer segments.deinit();
    
    var total: Int = 0;
    var max_x: Int = -1000000000;
    for (segments.items) |seg| {
        if (seg.end <= max_x) {
            continue;
        }
        var lx = max(seg.start, max_x + 1);
        var rx = seg.end;
        var count_of_beacons: Int = 0;
        for (beacons.items) |beacon| {
            if (beacon.y == target_y and lx <= beacon.x and beacon.x <= rx) {
                count_of_beacons += 1;
            }
        }

        total += rx - lx + 1 - count_of_beacons;
        max_x = rx;
    }

    print(total);
}

fn part2(alloc: Allocator, input_values: ArrayList(DevicePair)) !V {
    var y: Int = 0;
    while (y < 4000000) : (y += 1) {
        var segments = try getSegments(alloc, input_values, y);
        defer segments.deinit();

        var max_x: Int = -1000000000;
        var i: usize = 0;
        while (i < segments.items.len - 1) : (i += 1) {
            if (segments.items[i].end + 2 > max_x and segments.items[i].end + 2 == segments.items[i + 1].start) {
                return V.init(segments.items[i].end + 1, y);
            }
            max_x = max(max_x, segments.items[i].end);
        }
    }
    
    return V.init(-1, -1);
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var input_values = ArrayList(DevicePair).init(gpa);
    var beacons = ArrayList(V).init(gpa);
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var pattern = try regex.Regex.compile(gpa, "Sensor at x=(.*), y=(.*): closest beacon is at x=(.*), y=(.*)");

    while (line_it.next()) |line| {
        if (try pattern.match(line)) {
            var captures = (try pattern.captures(line)).?;
            var x1 = try parseNumber(captures.sliceAt(1).?);
            var y1 = try parseNumber(captures.sliceAt(2).?);
            var x2 = try parseNumber(captures.sliceAt(3).?);
            var y2 = try parseNumber(captures.sliceAt(4).?);

            var sensor = V.init(x1, y1);
            var beacon = V.init(x2, y2);
            try input_values.append(DevicePair.init(sensor, beacon));
            if (!contains(beacons, beacon)) {
                try beacons.append(beacon);
            }
        } else {
            unreachable;
        }
    }

    try part1(gpa, input_values, beacons);
    var answer = try part2(gpa, input_values);
    var x: Ulong = @intCast(Ulong, answer.x);
    var y: Ulong = @intCast(Ulong, answer.y);
    print(x * 4000000 + y);
}
