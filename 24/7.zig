const std = @import("std");
const print = std.debug.print;
const comptimePrint = std.fmt.comptimePrint;

const day = comptimePrint("{any}", .{@This()}); // n.zig -> n
const input = @embedFile(day ++ if (false) ".data" else ".input");

const Operation = struct { res: usize, args: std.ArrayList(usize), optional_valid: ?bool };
const Operations = []Operation;

pub fn parseInt(num: []const u8) !usize {
    return try std.fmt.parseInt(usize, num, 10);
}

pub fn mod(numerator: usize, denominator: usize) !usize {
    return try std.math.mod(usize, numerator, denominator);
}

pub fn nthDigitInBase(num: usize, n: usize, base: u8) usize {
    var buffer = std.mem.zeroes([64]u8);
    const num_in_base_3 = std.fmt.bufPrintIntToSlice(&buffer, num, base, .lower, .{ .width = n + 1, .fill = '0' });
    return num_in_base_3[num_in_base_3.len - n - 1] - '0'; // Get digit in reverse order
}

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

pub fn main() !void {

    // 1. Setup memory
    var ops = std.ArrayList(Operation).init(std.heap.page_allocator);
    defer {
        for (ops.items) |op| op.args.deinit();
        ops.deinit();
    }

    // 2. Parse input
    var ops_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (ops_iter.next()) |op| {
        var res_args_iter = std.mem.tokenizeAny(u8, op, " :");

        const res = try parseInt(res_args_iter.next().?);

        var args = std.ArrayList(usize).init(std.heap.page_allocator);
        while (res_args_iter.next()) |arg| try args.append(try parseInt(arg));

        try ops.append(.{ .res = res, .args = args, .optional_valid = null });
    }

    print(
        \\Day {s}
        \\Part 1: {d}
        \\Part 2: {d}
        \\
    , .{
        day,
        try part1(ops),
        try part2(ops),
    });
}

fn part1(ops: std.ArrayList(Operation)) !usize {
    var sum: usize = 0;

    op: for (ops.items) |op| {
        const number_of_combinations = std.math.pow(usize, operators[0..2].len, op.args.items.len - 1);
        // Bijective map (1 to 1) of nth op between args to nth bit in number_of_combinations
        // Bit = 0 => + and bit = 1 => *
        // By always adding one we go through all the different combinations
        for (0..number_of_combinations) |i| {
            var computed = op.args.items[0];
            for (op.args.items[1..], 0..) |arg, j| {
                computed = operators[(i >> @as(u6, @intCast(j))) & 1](computed, arg);
            }
            if (computed == op.res) {
                sum += op.res;
                continue :op;
            }
        }
    }
    return sum;
}

fn part2(ops: std.ArrayList(Operation)) !usize {
    var sum: usize = 0;

    // Same trick as in one, but we use base 3
    op: for (ops.items) |op| {
        const number_of_combinations = std.math.pow(usize, operators.len, op.args.items.len - 1);
        for (0..number_of_combinations) |i| {
            var computed = op.args.items[0];
            for (op.args.items[1..], 0..) |arg, j| {
                computed = operators[nthDigitInBase(i, j, 3)](computed, arg);
            }
            if (computed == op.res) {
                sum += op.res;
                continue :op;
            }
        }
    }
    return sum;
}
