// Advent of Code 2024-12-04 in zig comptime

// On windows the object file might have a different file ending
// zig build-obj 4.zig && objcopy --output-target=binary --only-section=solution 4.o solution.txt && cat solution.txt

// 1. Put the solution as constant/hardcoded value into its own linkersection
// 2. Yonik the bytes out of the linkersection into a txt file using objcopy
// 3. cat txt file
// 4. Profit -> Claim a runtime of 0.000000000000000000000000000000000000000000000000000000000000000000000000000s

pub export const result linksection("solution") = std.fmt.comptimePrint("{s}\n{s}\n{s}\n", .{
    "How many times does XMAS appear?",
    std.fmt.comptimePrint("Part 1: XMAS appears {d} times.", .{part1()}),
    std.fmt.comptimePrint("Part 2: X appears {d} times.", .{part2()}),
}).*;

const std = @import("std");
const eql = std.mem.eql;

const raw_data = @embedFile("4.data");

// Len without newline
const line_len = blk: {
    var len: i32 = 0;
    for (raw_data) |c| {
        if (c == '\n') break else len += 1;
    }
    break :blk len;
};
const line_len_newline = line_len + 1;
const lines = raw_data.len / line_len_newline;

// Cast the raw_data into a https://ziglang.org/documentation/master/#Sentinel-Terminated-Arrays
const data = @as(*const [lines][line_len:'\n']u8, @ptrCast(raw_data));

const Direction = enum { right, left, up, down, right_up, right_down, left_up, left_down };
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

fn at(y: i32, x: i32) u8 {
    return data[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
}
fn offset(word: []const u8, on: bool) i32 {
    return if (on) word.len - 1 else 0;
}
// We can always loop in the same direction, top to bottom and left to right
// Imagine 'bytes' as a vector pointing in the direction
// We just move the end of the vector around while respecting the array bounds
fn part1() usize {
    const w = "XMAS";
    var occurences: usize = 0;
    inline for (std.meta.tags(Direction)) |d| {
        const m = directionToMove(d);
        inline for (offset(w, m.y == -1)..lines - offset(w, m.y == 1)) |yu| {
            const y = @as(i32, @intCast(yu));
            inline for (offset(w, m.x == -1)..line_len - offset(w, m.x == 1)) |xu| {
                const x = @as(i32, @intCast(xu));
                const bytes = [_]u8{
                    at(y + 0 * m.y, x + 0 * m.x),
                    at(y + 1 * m.y, x + 1 * m.x),
                    at(y + 2 * m.y, x + 2 * m.x),
                    at(y + 3 * m.y, x + 3 * m.x),
                };
                @setEvalBranchQuota(10000000);
                if (eql(u8, w, &bytes)) {
                    occurences += 1;
                }
            }
        }
    }
    return occurences;
}

// We can always loop in the same direction, top to bottom and left to right
// The X/'cross' sweeps around the 2d array
// We just try all rotations of the X/'cross'
fn part2() usize {
    var occurences: usize = 0;
    inline for (1..lines - 1) |y| {
        inline for (1..line_len - 1) |x| {
            const cross = [_]u8{
                data[y - 1][x - 1],
                data[y - 1][x + 1],
                data[y][x],
                data[y + 1][x - 1],
                data[y + 1][x + 1],
            };
            @setEvalBranchQuota(10000000);
            for ([_][]const u8{ "MSAMS", "SMASM", "SSAMM", "MMASS" }) |w| {
                if (eql(u8, w, &cross)) {
                    occurences += 1;
                    break;
                }
            }
        }
    }
    return occurences;
}
