const std = @import("std");

const data = @embedFile("1.data");

const LocationID = i32;
const Distance = LocationID;

pub fn distance(id1: LocationID, id2: LocationID) Distance {
    return @max(id1, id2) - @min(id1, id2);
}

pub fn main() !void {
    // 1. Setup
    var lhs = std.ArrayList(LocationID).init(std.heap.page_allocator);
    defer lhs.deinit();
    var rhs = std.ArrayList(LocationID).init(std.heap.page_allocator);
    defer rhs.deinit();

    // 2. Parse
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        // Split on <Space> and remove carriage return and line feed
        var iterator = std.mem.tokenizeAny(u8, line, " \r\n");
        try lhs.append(try std.fmt.parseInt(LocationID, iterator.next().?, 10));
        try rhs.append(try std.fmt.parseInt(LocationID, iterator.next().?, 10));
    }

    // 3. Sort
    std.mem.sort(LocationID, lhs.items, {}, comptime std.sort.asc(LocationID));
    std.mem.sort(LocationID, rhs.items, {}, comptime std.sort.asc(LocationID));

    // 4. Compute distance
    const total_distance = blk: {
        var sum: Distance = 0;
        for (lhs.items, rhs.items) |l, r| sum += distance(l, r);
        break :blk sum;
    };

    std.debug.print("Total distance: {d}\n", .{total_distance});
}
