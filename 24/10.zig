const std = @import("std");

const allocator = std.heap.page_allocator;
const Point = @Vector(2, isize);
const raw_data = if (false)
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
    \\
else
    @embedFile("10.input");

pub fn main() !void {
    // Parse
    var lines = std.mem.tokenizeScalar(u8, raw_data, '\n');

    var lake = std.ArrayList([]const u8).init(allocator);
    var starting_positions = std.ArrayList(Point).init(allocator);

    var y: isize = 0;
    while (lines.next()) |line| : (y += 1) {
        for (line, 0..) |c, x| {
            if (c == '0') try starting_positions.append(Point{ y, @intCast(x) });
        }
        try lake.append(line);
    }
    std.debug.print("{d}, {any}\n", .{ starting_positions.items.len, starting_positions.items });
    std.debug.print("{d}, {any}\n", .{ lake.items.len, lake.items });

    std.debug.assert(lake.items.len == y);
    var res = Point{ 0, 0 };
    var ending_positions = std.AutoHashMap(Point, void).init(allocator);
    for (starting_positions.items) |pos| {
        res += try walk_trail(&lake, &ending_positions, pos, .{ y, @intCast(lake.items[0].len) });
    }
    std.debug.print("{d} {d}\n", .{ res[0], res[1] });
}

pub fn walk_trail(
    lake: *std.ArrayList([]const u8),
    ending_positions: *std.AutoHashMap(Point, void),
    pos: Point,
    corner: Point,
) !Point {
    const current_c = lake.*.items[@intCast(pos[0])][@intCast(pos[1])];

    if (current_c == '0') ending_positions.*.clearAndFree(); // Reset hashmap
    if (current_c == '9') {
        try ending_positions.*.put(pos, {}); // Reached end of trail
        return .{ 0, 1 };
    }
    const directions = [_]Point{ .{ 0, 1 }, .{ 0, -1 }, .{ 1, 0 }, .{ -1, 0 } };
    var res = Point{ 0, 0 };
    for (directions) |dir| {
        const new_pos = pos + dir;
        // Check if new_pos is in bounds
        const in_y = 0 <= new_pos[0] and new_pos[0] < corner[0];
        const in_x = 0 <= new_pos[1] and new_pos[1] < corner[1];

        if (in_y and in_x) {
            // Check if valid
            const new_c = lake.*.items[@intCast(new_pos[0])][@intCast(new_pos[1])];
            const valid = new_c == (current_c + 1);
            if (valid) res += try walk_trail(lake, ending_positions, new_pos, corner);
        }
    }
    return .{ ending_positions.*.count(), res[1] };
}
