const std = @import("std");
const regex = @import("regex");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const max = std.math.max;

const Int = u32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;

const input = @embedFile("input.txt");

fn parseNumber(string: String) !Int {
    return std.fmt.parseInt(Int, string, 10);
}

const InputValve = struct {
    id: String,
    flow_rate: Int,
    neighbors: ArrayList(String),
    fn init(id: String, flow_rate: Int, neighbors: ArrayList(String)) InputValve {
        return InputValve { .id = id, .flow_rate = flow_rate, .neighbors = neighbors };
    }
};

const Valve = struct {
    flow_rate: Int,
    neighbors: ArrayList(Int),
    fn init(flow_rate: Int, neighbors: ArrayList(Int)) Valve {
        return Valve { .flow_rate = flow_rate, .neighbors = neighbors };
    }
};

const State = struct {
    open_mask: Ulong,
    valve_index: Int,
    fn init(open_mask: Ulong, valve_index: Int) State {
        return State { .open_mask = open_mask, .valve_index = valve_index };
    }
};

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

fn hasBit(value: Ulong, index: anytype) bool {
    return value & std.math.shl(Ulong, 1, index) != 0;
}

test "HasBit" {
    try std.testing.expect(hasBit(5, 0) == true);
    try std.testing.expect(hasBit(5, 1) == false);
    try std.testing.expect(hasBit(5, 2) == true);
}

fn numOfEntries(map: anytype) Int {
    var it = map.iterator();
    var num_of_entries: Int = 0;
    while (it.next()) |_| {
        num_of_entries += 1;
    }

    return num_of_entries;
}

fn getPressureDropForEachValvesMask(valves: ArrayList(Valve), start_index: Int, max_time: Int, allocator: Allocator) !std.AutoHashMap(State, Int) {
    var front = std.AutoHashMap(State, Int).init(allocator);
    try front.put(State.init(0, start_index), 0);
    var time: Int = 1;
    while (time <= max_time) : (time += 1) {
        var next_front = std.AutoHashMap(State, Int).init(allocator);
        var open_masks = ArrayList(Ulong).init(allocator);
        var front_it = front.keyIterator();

        while (front_it.next()) |key| {
            if (std.mem.indexOfScalar(Ulong, open_masks.items, key.open_mask) == null) {
                try open_masks.append(key.open_mask);
            }
        }
        for (open_masks.items) |open_mask| {
            var this_tick_drop: Int = 0;
            for (valves.items) |valve, i| {
                if (valve.flow_rate > 0 and hasBit(open_mask, i)) {
                    this_tick_drop += valve.flow_rate;
                }
            }

            var front_it_2 = front.keyIterator();
            while (front_it_2.next()) |key_2| {
                if (key_2.open_mask != open_mask) {
                    continue;
                }

                var valve_index = key_2.valve_index;
                var valve = valves.items[@intCast(usize, key_2.valve_index)];
                var total_drop = front.get(key_2.*).?;
                var next_total_drop = total_drop + this_tick_drop;

                if (!hasBit(open_mask, valve_index) and valve.flow_rate > 0) {
                    var next_open_mask = open_mask | (std.math.shl(Ulong, 1, valve_index));
                    var state = State.init(next_open_mask, valve_index);
                    if (!next_front.contains(state)) {
                        try next_front.put(state, next_total_drop);
                    } else {
                        try next_front.put(state, max(next_total_drop, next_front.get(state).?));
                    }
                }

                for (valve.neighbors.items) |next_valve_index | {
                    var state = State.init(open_mask, next_valve_index);
                    if (!next_front.contains(state)) {
                        try next_front.put(state, next_total_drop);
                    } else {
                        try next_front.put(state, max(next_total_drop, next_front.get(state).?));
                    }
                }
            }
        }
        front = try next_front.clone();
    }

    return front;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var input_valves = ArrayList(InputValve).init(gpa);
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var pattern = try regex.Regex.compile(gpa, "Valve (.*) has flow rate=(.*); tunnels? leads? to valves? (.*)");

    while (line_it.next()) |line| {
        if (try pattern.match(line)) {
            var captures = (try pattern.captures(line)).?;
            var id = captures.sliceAt(1).?;
            var rate = try parseNumber(captures.sliceAt(2).?);
            var neighbors_str = captures.sliceAt(3).?;
            var neighbors = ArrayList(String).init(gpa);
            var n_it = std.mem.tokenize(Byte, neighbors_str, ", ");
            while (n_it.next()) |n| {
                try neighbors.append(n);
            }

            try input_valves.append(InputValve.init(id, rate, neighbors));
        } else {
            unreachable;
        }
    }

    var valve_indices = std.StringHashMap(Int).init(gpa);
    for (input_valves.items) |input_valve, i| {
        try valve_indices.put(input_valve.id, @intCast(Int, i));
    }

    var valves = ArrayList(Valve).init(gpa);
    for (input_valves.items) |input_valve| {
        var neighbors_indices = ArrayList(Int).init(gpa);
        for (input_valve.neighbors.items) |n| {
            var idx = valve_indices.get(n).?;
            try neighbors_indices.append(idx);
        }
        try valves.append(Valve.init(input_valve.flow_rate, neighbors_indices));
    }
    var start_valve_index = valve_indices.get("AA").?;
    var pressure_drops = try getPressureDropForEachValvesMask(valves, start_valve_index, 30, gpa);
    var max_value: Int = 0;

    var pressure_drops_it = pressure_drops.keyIterator();
    while (pressure_drops_it.next()) |it| {
        var value = pressure_drops.get(it.*).?;
        max_value = max(max_value, value);
    }
    std.debug.print("Max: {}\n", .{max_value});

    var dp = try getPressureDropForEachValvesMask(valves, start_valve_index, 26, gpa);
    var open_masks = ArrayList(Ulong).init(gpa);
    var dp_it = dp.keyIterator();
    var max_dp = std.AutoHashMap(Ulong, Ulong).init(gpa);
    while (dp_it.next()) |key| {
        if (std.mem.indexOfScalar(Ulong, open_masks.items, key.open_mask) == null) {
            try open_masks.append(key.open_mask);
        }
        if (!max_dp.contains(key.open_mask)) {
            try max_dp.put(key.open_mask, dp.get(key.*).?);
        } else {
            try max_dp.put(key.open_mask, max(max_dp.get(key.open_mask).?, dp.get(key.*).?));
        }
    }
    
    var answer_for_part_two: Ulong = 0;
    for (open_masks.items) |op_1| {
        for (open_masks.items) |op_2| {
            if (op_1 & op_2 != 0) {
                continue;
            }
            answer_for_part_two = max(answer_for_part_two, max_dp.get(op_1).? + max_dp.get(op_2).?);
        }
    }
    std.debug.print("Max for two: {}\n", .{answer_for_part_two});
}
