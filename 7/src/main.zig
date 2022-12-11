const std = @import("std");
const regex = @import("regex");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;

const Filesystem = std.StringHashMap(ArrayList([]const u8));

fn parseNumber(string: []const u8) !u64 {
    return std.fmt.parseInt(u64, string, 10);
}

fn size(filesystem: std.StringHashMap(ArrayList([]const u8)), path: []const u8, value: []const u8, allocator: Allocator) !u64 {
    var parsedValue = parseNumber(value) catch 0;
    if (parsedValue != 0) {
        return parsedValue;
    }

    var new_path = ArrayList(u8).init(allocator);
    try new_path.appendSlice(path);
    try new_path.appendSlice("/");
    try new_path.appendSlice(value);
    return getSize(filesystem, new_path.items, allocator);
}


fn getSize(filesystem: std.StringHashMap(ArrayList([]const u8)), path: []const u8, allocator: Allocator) u64 {
    var total: u64 = 0;
    for (filesystem.get(path).?.items) |x| {
        total += size(filesystem, path, x, allocator) catch 0;
    }

    return total;
}

const input = @embedFile("input.txt");
pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var filesystem = Filesystem.init(gpa);
    defer filesystem.deinit();
    
    var cd_dir = try regex.Regex.compile(gpa, "\\$ cd (.*)");
    var dir = try regex.Regex.compile(gpa, "dir (.*)");
    var file = try regex.Regex.compile(gpa, "(\\d+) (.*)");
    defer cd_dir.deinit();
    defer dir.deinit();
    defer file.deinit();

    var path = ArrayList([]const u8).init(gpa);   
    defer path.deinit();
    try path.append("");

    var it = std.mem.tokenize(u8, input, "\n");
    while (it.next()) |cmd| {
        if (eql(u8, cmd, "$ cd ..")) {
            _ = path.pop();
            continue;
        }
        if (eql(u8, cmd, "$ cd /")) {
            path.clearRetainingCapacity();
            try path.append("");
            continue;
        }
        if (try cd_dir.match(cmd)) {
            var captures = (try cd_dir.captures(cmd)).?;
            var dir_name = captures.sliceAt(1).?;
            try path.append(dir_name);
            continue;
        }
        if (eql(u8, cmd, "$ ls")) {
            continue;
        }
        if (try dir.match(cmd)) {
            var captures = (try dir.captures(cmd)).?;
            var dir_name = captures.sliceAt(1).?;
            var curr_path = try std.mem.join(gpa, "/", path.items);
            var files_in_dir = if (filesystem.contains(curr_path))
                filesystem.get(curr_path).? else 
                ArrayList([]const u8).init(gpa);
            try files_in_dir.append(dir_name);
            try filesystem.put(curr_path, files_in_dir);
            continue;
        }
        if (try file.match(cmd)) {
            var captures = (try file.captures(cmd)).?;
            var file_size = captures.sliceAt(1).?;
            var curr_path = try std.mem.join(gpa, "/", path.items);
            var files_in_dir = if (filesystem.contains(curr_path))
                filesystem.get(curr_path).? else 
                ArrayList([]const u8).init(gpa);
            try files_in_dir.append(file_size);
            try filesystem.put(curr_path, files_in_dir);
            continue;
        }
    }

    var answer_for_part_one: u64 = 0;
    var limit_for_part_two: u64 = 30000000 - (70000000 - getSize(filesystem, "", gpa));
    var answer_for_part_two: u64 = std.math.maxInt(u64);

    var keyIt = filesystem.keyIterator();
    while (keyIt.next()) |key| {
        var size_of_dir = getSize(filesystem, key.*, gpa);
        if (size_of_dir <= 100000) {
            answer_for_part_one += size_of_dir;
        }
        if (size_of_dir >= limit_for_part_two) {
            answer_for_part_two = std.math.min(answer_for_part_two, size_of_dir);
        }
    }
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}\n", .{answer_for_part_one});
    try stdout.print("{}\n", .{answer_for_part_two});
}
