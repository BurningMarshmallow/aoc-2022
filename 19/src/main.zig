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

fn parseLongNumber(string: String) !Ulong {
    return std.fmt.parseInt(Ulong, string, 10);
}

const Robot = struct {
    ore: Int,
    clay: Int,
    obsidian: Int,
    fn init(ore: Int, clay: Int, obsidian: Int) Robot {
        return Robot{ .ore = ore, .clay = clay, .obsidian = obsidian };
    }
};

const Materials = struct {
    ore: Int,
    clay: Int,
    obsidian: Int,
    geode: Int,
    fn init(ore: Int, clay: Int, obsidian: Int, geode: Int) Materials {
        return Materials{ .ore = ore, .clay = clay, .obsidian = obsidian, .geode = geode };
    }
};

const Blueprint = struct {
    robots: ArrayList(Robot),
    fn init(robots: ArrayList(Robot)) Blueprint {
        return Blueprint{ .robots = robots };
    }
};

fn printStr(value: anytype) void {
    std.debug.print("{s}\n", .{value});
}

fn print(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

fn collectMaterials(my_robots: ArrayList(Robot), materials: Materials) Materials {
    var ore = materials.ore;
    var clay = materials.clay;
    var obsidian = materials.obsidian;
    var geode = materials.geode;
    for (my_robots.items) |robot| {
        ore += robot.ore;
        clay += robot.clay;
        obsidian += robot.obsidian;
        geode += robot.geode;
    }

    return Materials.init(ore, clay, obsidian, geode);
}

fn getMaxGeodes(blueprint: Blueprint, my_robots: ArrayList(Robot), time_left: Int, materials: Materials) Int {
    if (time_left == 0) {
        var new_materials = collectMaterials(my_robots, materials);
        return new_materials.geode;
    }

    var m: Int = -1;
    for (blueprint.robots.items) |robot| {
        if (canBuildRobot(robot, materials)) {
            // build
            // collect
            // run with new materials, time - 1, update m
        }
    }

    var new_materials = collectMaterials(my_robots, materials);
    return max(m, getMaxGeodes(blueprint, my_robots, time_left - 1, new_materials));
}

fn part1(alloc: Allocator, blueprints: ArrayList(Blueprint)) !Int {
    var sum: Int = 0;
    for (blueprints.items) |_, i| {
        var blueprint = blueprints.items[i]; // for non-const
        var my_robots = ArrayList(Robot).init(gpa);
        my_robots.append(Robot.init(1, 0, 0));
        var materials = Materials.init(0, 0, 0, 0);

        var quality = getMaxGeodes(blueprint, my_robots, 24, materials);
        sum += quality;
    }

    return sum;
}

// fn part2(alloc: Allocator, monkeys: ArrayList(Robot)) !void {
// }

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var blueprints_for_part_one = ArrayList(Blueprint).init(gpa);
    var line_it = std.mem.tokenize(Byte, input, "\r\n");
    var ore_pattern = try regex.Regex.compile(gpa, ".*ore robot costs (.*) ore.*");
    var clay_pattern = try regex.Regex.compile(gpa, ".*clay robot costs (.*) ore.*");
    var obsidian_pattern = try regex.Regex.compile(gpa, ".*obsidian robot costs (.*) ore and (.*) clay.*");
    var geode_pattern = try regex.Regex.compile(gpa, ".*geode robot costs (.*) ore and (.*) obsidian.*");

    while (line_it.next()) |line| {
        var ore_captures = try ore_pattern.captures(line).?;
        var ore_str = ore_captures.sliceAt(1).?;
        var ore = try parseNumber(items_str);
        var ore_robot = Robot.init(ore, 0, 0);

        var clay_captures = try clay_pattern.captures(line).?;
        ore = try parseNumber(clay_captures.sliceAt(1).?);
        var clay_robot = Robot.init(ore, 0, 0);

        var obsidian_captures = try obsidian_pattern.captures(line).?;
        ore = try parseNumber(obsidian_captures.sliceAt(1).?);
        var clay = try parseNumber(obsidian_captures.sliceAt(2).?);
        var obsidian_robot = Robot.init(ore, clay, 0);

        var geode_captures = try geode_pattern.captures(line).?;
        ore = try parseNumber(obsidian_captures.sliceAt(1).?);
        var obsidian = try parseNumber(obsidian_captures.sliceAt(2).?);
        var geode_robot = Robot.init(ore, 0, obsidian);

        var robots = ArrayList(Robot).init(gpa);
        try robots.append(ore_robot);
        try robots.append(clay_robot);
        try robots.append(obsidian_robot);
        try robots.append(geode_robot);

        try blueprints_for_part_one.append(Blueprint.init(robots));
        // try monkeys_for_part_two.append(Monkey.init(items_for_part_two, operation_str, operand_str, test_value, pos_value, neg_value));
    }

    try part1(gpa, blueprints_for_part_one);
    // try part2(gpa, monkeys_for_part_two);
}
