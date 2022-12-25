const std = @import("std");
const regex = @import("regex");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const max = std.math.max;
const min = std.math.min;

const Int = i32;
const Byte = u8;
const String = []const Byte;

const input = @embedFile("input.txt");

const Materials = struct {
    ore: Int,
    clay: Int,
    obsidian: Int,
    fn init(ore: Int, clay: Int, obsidian: Int) Materials {
        return Materials{ .ore = ore, .clay = clay, .obsidian = obsidian };
    }

    fn greater(self: *const Materials, other: Materials) bool {
        return self.ore >= other.ore and self.clay >= other.clay and self.obsidian >= other.obsidian;
    }

    fn minus(self: *const Materials, other: Materials) Materials {
        return Materials.init(self.ore - other.ore, self.clay - other.clay, self.obsidian - other.obsidian);
    } 
};

const RobotBlueprint = struct {
    materials: Materials,
    fn init(materials: Materials) RobotBlueprint {
        return RobotBlueprint{ .materials = materials };
    }
};

const Blueprint = struct {
    ore: RobotBlueprint,
    clay: RobotBlueprint,
    obsidian: RobotBlueprint,
    geode: RobotBlueprint,
    fn init(ore: RobotBlueprint, clay: RobotBlueprint, obsidian: RobotBlueprint, geode: RobotBlueprint) Blueprint {
        return Blueprint{ .ore = ore, .clay = clay, .obsidian = obsidian, .geode = geode };
    }
};

const RobotCollection = struct {
    ore: Int,
    clay: Int,
    obsidian: Int,
    geode: Int,
    fn init(ore: Int, clay: Int, obsidian: Int, geode: Int) RobotCollection {
        return RobotCollection{ .ore = ore, .clay = clay, .obsidian = obsidian, .geode = geode };
    }

    fn addRobot(self: *const RobotCollection, robot_id: Int) RobotCollection {
        return switch (robot_id) {
            0 => RobotCollection.init(self.ore + 1, self.clay, self.obsidian, self.geode),
            1 => RobotCollection.init(self.ore, self.clay + 1, self.obsidian, self.geode),
            2 => RobotCollection.init(self.ore, self.clay, self.obsidian + 1, self.geode),
            3 => RobotCollection.init(self.ore, self.clay, self.obsidian, self.geode + 1),
            else => unreachable
        };
    }
};

const State = struct {
    robots: RobotCollection, 
    time_left: Int, 
    materials: Materials, 
    fn init(robots: RobotCollection, time_left: Int, materials: Materials) State {
        return State { .robots = robots, .time_left = time_left, .materials = materials };
    }
};

fn parseNumber(string: String) !Int {
    return std.fmt.parseInt(Int, string, 10);
}

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

fn getLimits(blueprint: Blueprint) Materials {
    return Materials.init(
        max(blueprint.ore.materials.ore, std.math.max3(blueprint.clay.materials.ore, blueprint.obsidian.materials.ore, blueprint.geode.materials.ore)),
        blueprint.obsidian.materials.clay,
        blueprint.geode.materials.obsidian
    );
}

fn collectMaterials(materials: Materials, my_robots: RobotCollection, limits: Materials) Materials {
    return Materials.init(
        min(materials.ore + my_robots.ore, limits.ore * 2), // heuristic found out by BurlakovNick
        min(materials.clay + my_robots.clay, limits.clay * 2), 
        min(materials.obsidian + my_robots.obsidian, limits.obsidian * 2)
    );
}

fn getNeededMaterials(blueprint: Blueprint, i: Int) Materials{
    return switch (i) {
        0 => blueprint.ore.materials,
        1 => blueprint.clay.materials,
        2 => blueprint.obsidian.materials,
        3 => blueprint.geode.materials,
        else => unreachable
    };
}

fn canBuildRobot(blueprint: Blueprint, materials: Materials, i: Int) bool {
    var needed_materials = getNeededMaterials(blueprint, i);
    return materials.greater(needed_materials);
}

fn buildRobot(blueprint: Blueprint, materials: Materials, i: Int) Materials {
    var needed_materials = getNeededMaterials(blueprint, i);
    return materials.minus(needed_materials);
}

fn storeInCache(cache: *std.AutoHashMap(State, Int), state: State, result: Int) !Int {
    try cache.*.put(state, result);
    return result;
}

fn getMaxGeodesWithCache(blueprint: Blueprint, limits: Materials, cache: *std.AutoHashMap(State, Int), state: State) !Int {
    if (cache.contains(state)) {
        return cache.get(state).?;
    }

    var my_robots = state.robots;
    var time_left = state.time_left;
    var materials = state.materials;
    if (time_left == 0) {
        return try storeInCache(cache, state, 0);
    }

    var best = my_robots.geode * time_left;
    var i: Int = 3;
    while (i >= 0) : (i -= 1) {
        var reached_limit = switch (i) {
            0 => limits.ore <= my_robots.ore,
            1 => limits.clay <= my_robots.clay,
            2 => limits.obsidian <= my_robots.obsidian,
            else => false
        };

        if (reached_limit) {
            continue;
        }

        if (canBuildRobot(blueprint, materials, i)) {
            var new_materials = buildRobot(blueprint, materials, i);
            new_materials = collectMaterials(new_materials, my_robots, limits);
            var new_robots = my_robots.addRobot(i);
            var new_state = State.init(new_robots, time_left - 1, new_materials);
            best = max(best, my_robots.geode + try storeInCache(cache, new_state, try getMaxGeodesWithCache(blueprint, limits, cache, new_state)));
            if (i == 3) {
                return best;
            }
        }
    }

    var new_materials = collectMaterials(materials, my_robots, limits);
    var new_state = State.init(my_robots, time_left - 1, new_materials);
    return max(best, my_robots.geode + try storeInCache(cache, new_state, try getMaxGeodesWithCache(blueprint, limits, cache, new_state)));
}

fn getMaxGeodes(blueprint: Blueprint, limits: Materials, state: State, alloc: Allocator) !Int {
    var cache = std.AutoHashMap(State, Int).init(alloc);
    defer cache.deinit();
    return try getMaxGeodesWithCache(blueprint, limits, &cache, state);
}

fn part1(blueprints: ArrayList(Blueprint), alloc: Allocator) !Int {
    var sum: Int = 0;
    for (blueprints.items) |blueprint, i| {
        var my_robots = RobotCollection.init(1, 0, 0, 0);
        var materials = Materials.init(0, 0, 0);
        var limits = getLimits(blueprint);
        var state = State.init(my_robots, 24, materials);
        var quality = try getMaxGeodes(blueprint, limits, state, alloc);

        sum += quality * @intCast(Int, i + 1);
    }

    return sum;
}

fn part2(blueprints: ArrayList(Blueprint), alloc: Allocator) !Int {
    var product: Int = 1;
    for (blueprints.items) |blueprint, i| {
        if (i >= 3) {
            break;
        }
        var my_robots = RobotCollection.init(1, 0, 0, 0);
        var materials = Materials.init(0, 0, 0);
        var limits = getLimits(blueprint);
        var state = State.init(my_robots, 32, materials);
        var quality = try getMaxGeodes(blueprint, limits, state, alloc);

        product *= quality;
    }

    return product;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var blueprints = ArrayList(Blueprint).init(gpa);
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var ore_pattern = try regex.Regex.compile(gpa, ".*ore robot costs (.*?) ore. Each clay .*");
    var clay_pattern = try regex.Regex.compile(gpa, ".*clay robot costs (.*?) ore. Each obsidian .*");
    var obsidian_pattern = try regex.Regex.compile(gpa, ".*obsidian robot costs (.*?) ore and (.*?) clay.*");
    var geode_pattern = try regex.Regex.compile(gpa, ".*geode robot costs (.*?) ore and (.*?) obsidian.*");

    while (line_it.next()) |line| {
        var ore_captures = (try ore_pattern.captures(line)).?;
        var ore_str = ore_captures.sliceAt(1).?;
        var ore = try parseNumber(ore_str);
        var ore_robot = RobotBlueprint.init(Materials.init(ore, 0, 0));

        var clay_captures = (try clay_pattern.captures(line)).?;
        ore = try parseNumber(clay_captures.sliceAt(1).?);
        var clay_robot = RobotBlueprint.init(Materials.init(ore, 0, 0));

        var obsidian_captures = (try obsidian_pattern.captures(line)).?;
        ore = try parseNumber(obsidian_captures.sliceAt(1).?);
        var clay = try parseNumber(obsidian_captures.sliceAt(2).?);
        var obsidian_robot = RobotBlueprint.init(Materials.init(ore, clay, 0));

        var geode_captures = (try geode_pattern.captures(line)).?;
        ore = try parseNumber(geode_captures.sliceAt(1).?);
        var obsidian = try parseNumber(geode_captures.sliceAt(2).?);
        var geode_robot = RobotBlueprint.init(Materials.init(ore, 0, obsidian));

        try blueprints.append(Blueprint.init(ore_robot, clay_robot, obsidian_robot, geode_robot));
    }

    print(try part1(blueprints, gpa));
    print(try part2(blueprints, gpa));
}
