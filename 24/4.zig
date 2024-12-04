// Advent of Code 2024-12-04 in zig comptime

// zig build-obj 4.zig && objcopy --output-target=binary --only-section=solution 4.o solution.txt && cat solution.txt

// 1. Put the solution as constant/hardcoded value into its own linkersection
// 2. Yonik the bytes out of the linkersection into a txt file using objcopy
// 3. cat txt file
// 4. Profit -> Claim a runtime of 0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000s

pub export const result linksection("solution") = std.fmt.comptimePrint("{s}\n{s}\n", .{
    "How many times does XMAS appear?",
    std.fmt.comptimePrint("Part 1: XMAS appears {d} times.", .{part1()}),
}).*;

const std = @import("std");
const eql = std.mem.eql;

// Cast the raw_data into a https://ziglang.org/documentation/master/#Sentinel-Terminated-Arrays
const raw_data = @embedFile("4.data");

// const raw_data =
//     \\MMMSXXMASM
//     \\MSAMXMSMSA
//     \\AMXSXMAAMM
//     \\MSAMASMSMX
//     \\XMASAMXAMM
//     \\XXAMMXXAMA
//     \\SMSMSASXSS
//     \\SAXAMASAAA
//     \\MAMMMXMMMM
//     \\MXMXAXMASX
//     \\
// ;

// Len without newline
const line_len = blk: {
    var len: usize = 0;
    for (raw_data) |c| {
        if (c == '\n') break else len += 1;
    }
    break :blk len;
};
const line_len_newline = line_len + 1;
const lines = raw_data.len / line_len_newline;

const data = @as(*const [lines][line_len:'\n']u8, @ptrCast(raw_data));

const Direction = enum {
    right,
    left,
    up,
    down,
    right_up,
    right_down,
    left_up,
    left_down,
};
const Move = struct { x: i32, y: i32 };

fn directionToMove(d: Direction) Move {
    return switch (d) {
        .right => .{ .x = 1, .y = 0 },
        .left => .{ .x = -1, .y = 0 },
        .up => .{ .x = 0, .y = 1 },
        .down => .{ .x = 0, .y = -1 },
        .right_up => .{ .x = 1, .y = 1 },
        .right_down => .{ .x = 1, .y = -1 },
        .left_up => .{ .x = -1, .y = 1 },
        .left_down => .{ .x = -1, .y = -1 },
    };
}

fn part1() usize {
    const word = "XMAS";
    const word_offset = word.len - 1;
    var occurences: usize = 0;
    inline for (std.meta.tags(Direction)) |d| {
        const m = directionToMove(d);
        var y: i32 = if (m.y == -1) word_offset else 0;
        const endXOffset = if (m.x == 1) word_offset else 0;
        const endYOffset = if (m.y == 1) word_offset else 0;

        // We can always loop in the same direction, top to bottom and left to right
        // Imagine 'bytes' as a vector pointing in the direction
        // We just move the end of the vector around while respecting the array bounds
        while (y < lines - endYOffset) : (y += 1) {
            var x: i32 = if (m.x == -1) word_offset else 0;
            while (x < line_len - endXOffset) : (x += 1) {
                const bytes = [_]u8{
                    data[@as(usize, @intCast(y + 0 * m.y))][@as(usize, @intCast(x + 0 * m.x))],
                    data[@as(usize, @intCast(y + 1 * m.y))][@as(usize, @intCast(x + 1 * m.x))],
                    data[@as(usize, @intCast(y + 2 * m.y))][@as(usize, @intCast(x + 2 * m.x))],
                    data[@as(usize, @intCast(y + 3 * m.y))][@as(usize, @intCast(x + 3 * m.x))],
                };
                @setEvalBranchQuota(10000000);
                if (eql(u8, word, &bytes)) {
                    occurences += 1;
                }
            }
        }
    }
    return occurences;
}

pub fn main() !void {
    std.debug.print("Lines: {d}, LineLen: {d}\n", .{ lines, line_len });
    for (data) |row| std.debug.print("{s}\n", .{row});
    std.debug.print("Part 1: XMAS appears {d} times.\n", .{part1()});
}
