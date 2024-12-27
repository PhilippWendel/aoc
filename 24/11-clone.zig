const std = @import("std");

const allocator = std.heap.page_allocator;
const raw_data = if (false) "125 17" else @embedFile("11.input");

pub fn main() !void {
    // Parse
    var stones_iter = std.mem.tokenizeAny(u8, raw_data, " \n");
    var stones = std.AutoHashMap(u64, u64).init(allocator);
    defer stones.deinit();

    while (stones_iter.next()) |stone| {
        const key = try std.fmt.parseInt(u64, stone, 10);
        const old_count = stones.get(key) orelse 0;
        try stones.put(key, old_count + 1);
    }

    const blinks = 75;
    for (1..blinks + 1) |i| {
        const stones_old = try stones.clone();
        stones.clearAndFree();

        // tick = !tick;

        var keys = stones_old.keyIterator();
        while (keys.next()) |key| {
            const nums = try apply_rules(key.*);
            for (nums) |num| {
                if (num) |n| {
                    try stones.put(n, (stones.get(n) orelse 0) + stones_old.get(key.*).?);
                }
            }
        }
        if (i == 25 or i == 75) {
            var values = stones.valueIterator();
            var sum: u64 = 0;
            while (values.next()) |v| sum += v.*;
            std.debug.print("{d}: {d}\n", .{ i, sum });
        }
    }
}

fn apply_rules(num: u64) ![2]?u64 {
    if (num == 0) return .{ 1, null };

    const digits = try std.fmt.allocPrint(allocator, "{d}", .{num});
    defer allocator.free(digits);

    if (digits.len & 1 == 0) {
        const middle = digits.len / 2;
        const l = try std.fmt.parseInt(u64, digits[0..middle], 10);
        const r = try std.fmt.parseInt(u64, digits[middle..], 10);
        return .{ l, r };
    }

    return .{ num * 2024, null };
}
