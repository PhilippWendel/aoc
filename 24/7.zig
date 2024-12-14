const std = @import("std");
const print = std.debug.print;
const comptimePrint = std.fmt.comptimePrint;

const day = comptimePrint("{any}", .{@This()}); // n.zig -> n
const input = @embedFile(day ++ if (true) ".data" else ".input");

pub fn parseInt(num: []const u8) !usize {
    return try std.fmt.parseInt(usize, num, 10);
}

const Operation = struct { res: usize, args: std.ArrayList(usize) };

pub fn nthDigitInBase(num: usize, n: usize, base: usize) usize {
    var buffer = std.mem.zeroes([64]u8);
    const num_in_base_3 = std.fmt.bufPrintIntToSlice(&buffer, num, @truncate(base), .lower, .{ .width = n + 1, .fill = '0' });
    return num_in_base_3[num_in_base_3.len - n - 1] - '0'; // Get digit in reverse order
}

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

        const res = try parseInt(res_args_iter.next().?);

        var args = std.ArrayList(usize).init(std.heap.page_allocator);
        while (res_args_iter.next()) |arg| try args.append(try parseInt(arg));

        try operations.append(.{ .res = res, .args = args });
    }

    // 3. Operators
    const operators = [_](*const fn (a: usize, b: usize) usize){
        (struct {
            pub fn f(a: usize, b: usize) usize {
                return a + b;
            }
        }).f,
        (struct {
            pub fn f(a: usize, b: usize) usize {
                return a * b;
            }
        }).f,
        (struct {
            pub fn f(a: usize, b: usize) usize {
                var buffer = std.mem.zeroes([64]u8);
                const concated_num = std.fmt.bufPrint(buffer[0..], "{d}{d}", .{ a, b }) catch unreachable;
                return parseInt(concated_num) catch unreachable;
            }
        }).f,
    };

    print(
        \\Day {s}
        \\Part 1: {d}
        \\Part 2: {d}
        \\
    , .{
        day,
        try solve(operations.items, operators[0..2]),
        try solve(operations.items, operators[0..]),
    });
}

fn solve(operations: []Operation, operators: []const (*const fn (a: usize, b: usize) usize)) !usize {
    var sum: usize = 0;

    op: for (operations) |op| {
        const number_of_combinations = std.math.pow(usize, operators.len, op.args.items.len - 1);
        for (0..number_of_combinations) |i| {
            var res = op.args.items[0];
            for (op.args.items[1..], 0..) |arg, j| res = operators[nthDigitInBase(i, j, operators.len)](res, arg);

            if (res == op.res) {
                sum += op.res;
                continue :op;
            }
        }
    }
    return sum;
}
