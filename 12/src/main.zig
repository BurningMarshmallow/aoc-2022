const std = @import("std");
const Queue = @import("queue").Queue;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const min = std.math.min;

const Int = i32;
const Byte = u8;
const String = []const Byte;
const Ulong = u64;
const N = 41;
const M = 167;

const V = struct {
    x: Int,
    y: Int,
    fn plus(self: *V, other: V) V {
        return V{ .x = self.x + other.x, .y = self.y + other.y };
    }
    fn init(x: Int, y: Int) V {
        return V { .x = x, .y = y };
    }
    fn initUsize(x: usize, y: usize) V {
        return V { .x = @intCast(Int, x), .y = @intCast(Int, y) };
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

fn at(heightmap: [N][M]Byte, pos: V) ?Byte {
    if (0 <= pos.x and pos.x < N) {
        if (0 <= pos.y and pos.y < M) {
            return heightmap[@intCast(usize, pos.x)][@intCast(usize, pos.y)];
        }
    }
    return null;
}

fn bfs(heightmap: [N][M]Byte, start_pos: V, end_pos: V) !Int {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    
    var q = Queue(State).init(gpa);
    try q.enqueue(State.init(0, start_pos));
    var vis = std.AutoHashMap(V, void).init(gpa);
    try vis.put(start_pos, {});
    while(!q.empty()) {
        var state = q.dequeue().?;
        if (state.node.x == end_pos.x and state.node.y == end_pos.y) {
            return state.dist;
        }

        var offsets = [_]V { V.init(-1, 0), V.init(1, 0), V.init(0, -1), V.init(0, 1) };
        for (offsets) |offset| {
            var new_node = state.node.plus(offset);
            var at_node: Byte = at(heightmap, state.node).?;
            var at_new_node: ?Byte = at(heightmap, new_node);
            if (at_new_node == null) {
                continue;
            }
            
            if (!vis.contains(new_node) and at_node + 1 >= at_new_node.?) {
                try q.enqueue(State.init(state.dist + 1, new_node));
                try vis.put(new_node, {});
            }
        }
    }

    return 1_000_000;
}

fn part2(heightmap: [N][M]Byte, start_pos: V, end_pos: V) !Int {
    var i: usize = 0;
    var m: Int = try bfs(heightmap, start_pos, end_pos);
    while (i < N) : (i += 1) {
        var j: usize = 0;
        while (j < M) : (j += 1) {
            if (heightmap[i][j] == 0) {
                var bfs_result = try bfs(heightmap, V.initUsize(i, j), end_pos);
                m = min(bfs_result, m);
            }
        }
    }

    return m;
}

pub fn main() !void {
    var heightmap = [1][M] Byte { [1]Byte{ 0 } ** M } ** N;
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var i: usize = 0;
    var start_pos: V = V.init(-1, -1);
    var end_pos: V = V.init(-1, -1);
    while (line_it.next()) |line| {
        var j: usize = 0;
        for (line) |char| {
            if (char == 'S') {
                start_pos = V.initUsize(i, j);
                heightmap[i][j] = 0;
            } else {
                if (char == 'E') {
                    end_pos = V.initUsize(i, j);
                    heightmap[i][j] = 25;
                } else {
                    heightmap[i][j] = char - 'a';
                }
            }
            j += 1;
        }
        i += 1;
    }

    print(try bfs(heightmap, start_pos, end_pos));
    print(try part2(heightmap, start_pos, end_pos));
}
