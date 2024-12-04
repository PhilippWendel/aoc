const std = @import("std");

const data = @embedFile("3.data");

pub fn main() !void {
    // 1. Setup
    var x = std.ArrayList(u32).init(std.heap.page_allocator);
    var y = std.ArrayList(u32).init(std.heap.page_allocator);
    defer x.deinit();
    defer y.deinit();

    const min_op_len = 3 + 2 + 2 + 1; // mul () XY ,
    // 2. Parse
    // Check for off by one or more error
    for (0..(data.len - min_op_len)) |offset| {
        const pos = data[offset..];

        if (!std.mem.eql(u8, "mul(", pos[0..4])) continue;
        var rest = pos[4..];

        const d = std.ascii.isDigit;
        const X = blk: {
            if (d(rest[0]) and d(rest[1]) and d(rest[2])) {
                const X = try std.fmt.parseInt(u32, rest[0..3], 10);
                rest = rest[3..];
                break :blk X;
            } else if (d(rest[0]) and d(rest[1])) {
                const X = try std.fmt.parseInt(u32, rest[0..2], 10);
                rest = rest[2..];
                break :blk X;
            } else if (d(rest[0])) {
                const X = try std.fmt.parseInt(u32, rest[0..1], 10);
                rest = rest[1..];
                break :blk X;
            } else continue;
        };

        if (rest[0] != ',') continue;
        rest = rest[1..];

        const Y = blk: {
            if (d(rest[0]) and d(rest[1]) and d(rest[2])) {
                const Y = try std.fmt.parseInt(u32, rest[0..3], 10);
                rest = rest[3..];
                break :blk Y;
            } else if (d(rest[0]) and d(rest[1])) {
                const Y = try std.fmt.parseInt(u32, rest[0..2], 10);
                rest = rest[2..];
                break :blk Y;
            } else if (d(rest[0])) {
                const Y = try std.fmt.parseInt(u32, rest[0..1], 10);
                rest = rest[1..];
                break :blk Y;
            } else continue;
        };

        if (rest[0] != ')') continue;

        try x.append(X);
        try y.append(Y);
    }

    // 3. Compute sum
    const sum = blk: {
        var sum: u32 = 0;
        for (x.items, y.items) |X, Y| {
            sum += X * Y;
        }
        break :blk sum;
    };

    std.debug.print("Sum: {d}\n", .{sum});
}
