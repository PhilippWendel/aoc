const std = @import("std");

const allocator = std.heap.page_allocator;
const raw_data = if (false)
    \\AAAA
    \\BBCD
    \\BBCC
    \\EEEC
else
    @embedFile("12.input");

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
}
