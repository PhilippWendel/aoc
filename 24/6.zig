const std = @import("std");
const print = std.debug.print;
const comptimePrint = std.fmt.comptimePrint;

const day = comptimePrint("{any}", .{@This()});
const input = @embedFile(day ++ if (false) ".data" else ".input");

// pub export const result linksection("solution") = comptimePrint("{s}\n{s}\n{s}\n", .{
//     "Day " ++ day,
//     comptimePrint("Part 1: {d}", .{part1()}),
//     comptimePrint("Part 2: {d}", .{part2()}),
// }).*;

pub fn main() void {
    // print("{s}", .{result});
    print("{d}\n", .{part2()});
}

const Guard = enum(u8) {
    Up = '^',
    Right = '>',
    Down = 'v',
    Left = '<',
    pub fn rotateRight(self: Guard) Guard {
        const tags = std.meta.tags(Guard);
        return tags[@rem(std.mem.indexOfScalar(Guard, tags, self).? + 1, tags.len)];
    }
};

const State = union(enum) {
    Visited,
    Unvisited,
    Obstruction,
    Guard: Guard,
};

const Field = [lines][line_len_without_newline]State;
const lines = blk: {
    @setEvalBranchQuota(std.math.maxInt(u32));
    break :blk std.mem.count(u8, input, "\n");
};
const line_len = input.len / lines;
const line_len_without_newline = line_len - 1;
const data = blk: {
    const unparsed = @as(*const [lines][line_len_without_newline:'\n']u8, @ptrCast(input));
    var parsed: [lines][line_len_without_newline]State = undefined;
    for (unparsed, 0..) |line, y| {
        @setEvalBranchQuota(std.math.maxInt(u32));
        for (line, 0..) |c, x| {
            parsed[y][x] = switch (c) {
                '.' => State.Unvisited,
                '#' => State.Obstruction,
                '^', '>', 'v', '<' => State{ .Guard = @enumFromInt(c) },
                else => unreachable,
            };
        }
    }
    break :blk parsed;
};

const Pos = struct {
    x: usize,
    y: usize,

    pub fn eq(l: Pos, r: Pos) bool {
        return l.x == r.x and l.y == r.y;
    }
};
const guardStart = blk: {
    @setEvalBranchQuota(std.math.maxInt(u32));
    const pos = for (std.meta.tags(Guard)) |tag| if (std.mem.indexOfScalar(u8, input, @intFromEnum(tag))) |i| break i;
    break :blk Pos{ .x = @rem(pos, line_len), .y = @divTrunc(pos, line_len) };
};

fn legalMove(pos: Pos, field: Field) bool {
    return switch (field[pos.y][pos.x].Guard) {
        .Up => 0 <= (@as(isize, @intCast(pos.y)) - 1),
        .Right => (pos.x + 1) < field[0].len,
        .Left => 0 <= (@as(isize, @intCast(pos.x)) - 1),
        .Down => (pos.y + 1) < field.len,
    };
}

fn move(pos: Pos, dir: Guard) Pos {
    return switch (dir) {
        .Up => .{ .x = pos.x, .y = pos.y - 1 },
        .Right => .{ .x = pos.x + 1, .y = pos.y },
        .Down => .{ .x = pos.x, .y = pos.y + 1 },
        .Left => .{ .x = pos.x - 1, .y = pos.y },
    };
}

fn count(field: Field, tag: State) usize {
    var sum = 0;
    for (field) |row| {
        for (row) |state| {
            if (std.meta.activeTag(state) == std.meta.activeTag(tag)) sum += 1;
        }
    }
    return sum;
}

fn part1() usize {
    var field: Field = undefined;
    @memcpy(&field, &data);
    var pos = guardStart;
    @setEvalBranchQuota(std.math.maxInt(u32));
    while (legalMove(pos, field)) {
        const current = &field[pos.y][pos.x];
        const newPos = move(pos, current.*.Guard);
        const new = &field[newPos.y][newPos.x];
        if (new.* != .Obstruction) {
            new.* = current.*;
            current.* = .Visited;
            pos = newPos;
        } else {
            current.*.Guard = current.*.Guard.rotateRight();
        }
    }
    return count(field, .Visited) + count(field, .{ .Guard = .Up });
}

fn part2() usize {
    var field: Field = undefined;
    @memcpy(&field, &data);

    const guard = field[guardStart.y][guardStart.x];
    var pos = guardStart;

    @setEvalBranchQuota(std.math.maxInt(u32));
    while (legalMove(pos, field)) {
        const current = &field[pos.y][pos.x];
        const newPos = move(pos, current.*.Guard);
        const new = &field[newPos.y][newPos.x];
        if (new.* != .Obstruction) {
            new.* = current.*;
            current.* = .Visited;
            pos = newPos;
        } else {
            current.*.Guard = current.*.Guard.rotateRight();
        }
    }

    const Hit = struct { pos: Pos, dir: Guard, visited: bool };
    var number_of_new_obstructions: usize = 0;

    for (field, 0..) |row, y| {
        for (row, 0..) |state, x| {
            if (state == .Obstruction) continue;
            if (state == .Unvisited) continue;
            if (guardStart.eq(.{ .x = x, .y = y })) continue;

            const old = field[y][x];
            defer field[y][x] = old;
            field[y][x] = .Obstruction;

            pos = guardStart;
            field[guardStart.y][guardStart.x] = guard;

            var hits: [lines * line_len]Hit = undefined;
            var current_obstruction: usize = 0;

            @setEvalBranchQuota(std.math.maxInt(u32));
            loop: while (legalMove(pos, field)) {
                const current = &field[pos.y][pos.x];
                const dir = current.*.Guard;
                const newPos = move(pos, dir);
                const new = &field[newPos.y][newPos.x];
                if (new.* != .Obstruction) {
                    new.* = current.*;
                    pos = newPos;
                } else {
                    hits[current_obstruction] = .{ .pos = newPos, .dir = dir, .visited = false };
                    current_obstruction += 1;
                    for (hits[0..current_obstruction]) |*hit| {
                        print("{s}", .{""});

                        if (hit.*.pos.eq(newPos) and hit.*.dir == dir) {
                            if (hit.*.visited) {
                                number_of_new_obstructions += 1;
                                break :loop;
                            } else hit.*.visited = true;
                        }
                    }
                    current.*.Guard = dir.rotateRight();
                }
            }
        }
    }

    return number_of_new_obstructions;
}
