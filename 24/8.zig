const std = @import("std");

const Point = @Vector(2, isize);
const allocator = std.heap.page_allocator;

const data = if (1 == 0)
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
    \\
else
    @embedFile("8.input");

pub fn main() !void {
    // 1. Setup
    var map = std.AutoHashMap(u8, std.ArrayList(Point)).init(allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |item| item.value_ptr.*.deinit();
        map.deinit();
    }

    // 2. Parse
    var lines_it = std.mem.tokenizeScalar(u8, data, '\n');
    var pt = Point{ @intCast(lines_it.peek().?.len), 0 };
    while (lines_it.next()) |row| : (pt[1] += 1) {
        for (row, 0..) |c, x| {
            if (c == '.') continue;
            if (!map.contains(c)) {
                const points = std.ArrayList(Point).init(allocator);
                try map.put(c, points);
            }
            try map.getPtr(c).?.*.append(.{ @intCast(x), pt[1] });
        }
    }

    // Part 1
    var antinodes = std.AutoHashMap(Point, void).init(allocator);
    defer antinodes.deinit();

    var map_it = map.valueIterator();
    while (map_it.next()) |value| {
        const positions = value.*.items;

        for (positions[0 .. positions.len - 1], 0..) |l, i| {
            for (positions[1 + i ..]) |r| {
                const distance = l - r;
                const overlaps = [_]Point{ l + distance, l - distance, r + distance, r - distance };
                for (overlaps) |p| {
                    if (@reduce(.And, p == l)) continue;
                    if (@reduce(.And, p == r)) continue;
                    if (inside(p, pt)) {
                        try antinodes.put(p, {});
                    }
                }
            }
        }
    }

    // Part 2
    var antinodes2 = std.AutoHashMap(Point, void).init(allocator);
    defer antinodes2.deinit();

    var map_it2 = map.valueIterator();
    while (map_it2.next()) |value| {
        const positions = value.*.items;
        for (positions[0 .. positions.len - 1], 0..) |l, i| {
            for (positions[1 + i ..]) |r| {
                const distance = l - r;
                for ([_]Point{ l, r }) |starting_point| {
                    inline for ([_](fn (Point, Point) Point){ add, sub }) |op| {
                        var p = op(starting_point, distance);
                        while (inside(p, pt)) : (p = op(p, distance)) try antinodes2.put(p, {});
                    }
                }
            }
        }
    }
    std.debug.print("Part 1:{d}\nPart 2: {d}\n", .{ antinodes.count(), antinodes2.count() });
}

fn inside(pos: Point, corner: Point) bool {
    return (0 <= pos[0]) and (pos[0] < corner[0]) and (0 <= pos[1]) and (pos[1] < corner[1]);
}

fn add(l: Point, r: Point) Point {
    return l + r;
}

fn sub(l: Point, r: Point) Point {
    return l - r;
}
