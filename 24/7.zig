const std = @import("std");

const day = std.fmt.comptimePrint("{any}", .{@This()}); // n.zig -> n
const input = @embedFile(day ++ if (true) ".data" else ".input");

const Operation = struct { res: usize, args: std.ArrayList(usize) };

pub fn main() !void {
    // 1. Setup memory
    var operations = std.ArrayList(Operation).init(std.heap.page_allocator);
    defer {
        for (operations.items) |op| op.args.deinit();
        operations.deinit();
    }
    // 2. Parse input
    var ops_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (ops_iter.next()) |op| {
        var res_args_iter = std.mem.tokenizeAny(u8, op, " :");
        const res = try std.fmt.parseInt(usize, res_args_iter.next().?, 10);
        var args = std.ArrayList(usize).init(std.heap.page_allocator);
        while (res_args_iter.next()) |arg| try args.append(try std.fmt.parseInt(usize, arg, 10));
        try operations.append(.{ .res = res, .args = args });
    }
    // 3. Display result
    std.debug.print("Day {s}\nPart 1: {d}\nPart 2: {d}\n", .{ day, try solve(operations.items, 2), try solve(operations.items, 3) });
}

// bijective map of operation to nth digit in number, base corresponds to the number of operations
pub fn nthDigitInBase(num: usize, n: usize, base: usize) usize {
    var buffer = std.mem.zeroes([64]u8);
    const num_in_base_3 = std.fmt.bufPrintIntToSlice(&buffer, num, @truncate(base), .lower, .{ .width = n + 1, .fill = '0' });
    return num_in_base_3[num_in_base_3.len - n - 1] - '0'; // Get digit in reverse order
}

fn solve(operations: []Operation, number_of_operators: usize) !usize {
    var sum: usize = 0;
    op: for (operations) |op| {
        // number_of_operators^(number_of_args - 1) => this gives all possible combinations
        const number_of_combinations = std.math.pow(usize, number_of_operators, op.args.items.len - 1);
        for (0..number_of_combinations) |i| {
            var res = op.args.items[0];
            for (op.args.items[1..], 0..) |arg, j| {
                res = switch (nthDigitInBase(i, j, number_of_operators)) {
                    0 => res + arg,
                    1 => res * arg,
                    else => blk: {
                        var buffer = std.mem.zeroes([64]u8);
                        const concated_num = std.fmt.bufPrint(buffer[0..], "{d}{d}", .{ res, arg }) catch unreachable;
                        break :blk std.fmt.parseInt(usize, concated_num, 10) catch unreachable;
                    },
                };
            }
            if (res == op.res) {
                sum += op.res;
                continue :op;
            }
        }
    }
    return sum;
}
