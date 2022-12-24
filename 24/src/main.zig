const std = @import("std");
const Queue = @import("queue").Queue;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Int = i32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;
const BlizzardsByCoordMap = std.AutoHashMap(Int, ArrayList(Blizzard));

const N = 102 - 2;
const M = 37 - 2;

const V = struct {
    x: Int,
    y: Int,
    fn plus(self: *V, other: V) V {
        return V{ .x = self.x + other.x, .y = self.y + other.y };
    }
    fn init(x: Int, y: Int) V {
        return V { .x = x, .y = y };
    }
    fn equalsTo(self: *const V, other: V) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Blizzard = struct {
    v: V,
    dir: V,
    fn init(v: V, dir: V) Blizzard {
        return Blizzard { .v = v, .dir = dir };
    }
};

const State = struct {
    dist: Int,
    node: V,
    fn init(dist: Int, node: V) State {
        return State { .dist = dist, .node = node };
    }
};

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

const input = @embedFile("input.txt");

fn numOfEntries(map: anytype) Int {
    var it = map.iterator();
    var num_of_entries: Int = 0;
    while (it.next()) |_| {
        num_of_entries += 1;
    }

    return num_of_entries;
}

fn addToQueue(q: *Queue(State), vis: *std.AutoHashMap(State, void), new_state: State) !void {
    if (!vis.contains(new_state)) {
        try q.*.enqueue(new_state);
        try vis.*.put(new_state, {});
    }
}

fn hasBlizzard(blizzards_x: BlizzardsByCoordMap, blizzards_y: BlizzardsByCoordMap, node: V, dist: Int) bool {
    if (blizzards_x.contains(node.x)) {
        for (blizzards_x.get(node.x).?.items) |blizzard| {
            var nx = @mod((blizzard.v.x + blizzard.dir.x * dist), N);
            var ny = @mod((blizzard.v.y + blizzard.dir.y * dist), M);

            if (node.equalsTo(V.init(nx, ny))) {
                return true;
            }
        }
    }

    if (blizzards_y.contains(node.y)) {
        for (blizzards_y.get(node.y).?.items) |blizzard| {
            var nx = @mod((blizzard.v.x + blizzard.dir.x * dist), N);
            var ny = @mod((blizzard.v.y + blizzard.dir.y * dist), M);
            if (node.x == nx and node.y == ny) {
                return true;
            }
        }
    }

    return false;
}

fn bfs(blizzards_x: BlizzardsByCoordMap, blizzards_y: BlizzardsByCoordMap, start_pos: V, end_pos: V, start_dist: Int) !Int {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    
    var q = Queue(State).init(gpa);
    var vis = std.AutoHashMap(State, void).init(gpa);
    defer vis.deinit();

    var init_state = State.init(start_dist, start_pos);
    try addToQueue(&q, &vis, init_state);

    while(!q.empty()) {
        var state = q.dequeue().?;
        if (state.node.equalsTo(end_pos)) {
            return state.dist;
        }

        var offsets = [_]V { V.init(-1, 0), V.init(1, 0), V.init(0, -1), V.init(0, 1) };
        for (offsets) |offset| {
            var new_node = state.node.plus(offset);
            var in_box = (0 <= new_node.x and new_node.x < N and 0 <= new_node.y and new_node.y < M) or new_node.equalsTo(end_pos);
            if (in_box and !hasBlizzard(blizzards_x, blizzards_y, new_node, state.dist + 1)) {
                try addToQueue(&q, &vis, State.init(state.dist + 1, new_node));
            }

            if (!hasBlizzard(blizzards_x, blizzards_y, state.node, state.dist + 1)) {
                try addToQueue(&q, &vis, State.init(state.dist + 1, state.node));
            }
        }
    }

    return 1_000_000;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var dirs = std.AutoHashMap(Byte, V).init(gpa);
    try dirs.put('<', V.init(-1, 0));
    try dirs.put('>', V.init(1, 0));
    try dirs.put('v', V.init(0, 1));
    try dirs.put('^', V.init(0, -1));
    var start_pos = V.init(-1, 0);
    var end_pos = V.init(N, M - 1);

    var blizzards_x = BlizzardsByCoordMap.init(gpa);
    var blizzards_y = BlizzardsByCoordMap.init(gpa);

    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    _ = line_it.next(); // Skip first line
    var i: Int = 0;
    while (line_it.next()) |line| {
        var j: Int = 0;
        for (line[1..]) |char| {
            var v = V.init(j, i);
            if (char == '.' or char == '#') {
                j += 1;
                continue;
            }

            var blizzard = Blizzard.init(v, dirs.get(char).?);
            if (blizzard.dir.x == 0) {
                var new_blizzards = if (blizzards_x.contains(j))
                    blizzards_x.get(j).? else 
                    ArrayList(Blizzard).init(gpa);
                try new_blizzards.append(blizzard);
                try blizzards_x.put(j, new_blizzards);
            } else {
                var new_blizzards = if (blizzards_y.contains(i))
                    blizzards_y.get(i).? else 
                    ArrayList(Blizzard).init(gpa);
                try new_blizzards.append(blizzard);
                try blizzards_y.put(i, new_blizzards);
            }
            j += 1;
        }
        i += 1;
    }

    var dist_1 = try bfs(blizzards_x, blizzards_y, start_pos, end_pos, 0);
    print(dist_1);
    var dist_2 = try bfs(blizzards_x, blizzards_y, end_pos, start_pos, dist_1);
    var dist_3 = try bfs(blizzards_x, blizzards_y, start_pos, end_pos, dist_2);
    print(dist_3);
}
