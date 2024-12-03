const std = @import("std");

const data = @embedFile("1.data");

const LocationID = i32;

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

    // 4. Compute similarity score
    const similarity_score = blk: {
        var sum: i32 = 0;
        for (lhs.items) |l| {
            var number_of_occurences_in_rhs: i32 = 0;
            for (rhs.items) |r| {
                if (l == r) number_of_occurences_in_rhs += 1;
            }
            sum += l * number_of_occurences_in_rhs;
        }
        break :blk sum;
    };

    std.debug.print("Similarity score: {d}\n", .{similarity_score});
}
