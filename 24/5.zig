// Only works with zig 0.11 wtf??? nix run nixpkgs#zig_0_11 -- run 5.zig

const std = @import("std");
const count = std.mem.count;
const print = std.debug.print;
const comptimePrint = std.fmt.comptimePrint;
const parseInt = std.fmt.parseInt;
const zeroes = std.mem.zeroes;

const MAX_U32 = std.math.maxInt(u32);
const day = comptimePrint("{any}", .{@This()});

const newline = "\n";
const input = @embedFile(day ++ if (true) ".data" else ".input");

pub export const result linksection("solution") = comptimePrint("{s}\n{s}\n{s}\n", .{
    "Day 5",
    comptimePrint("Part 1: {d}", .{part1()}),
    comptimePrint("Part 2: {d}", .{part2()}),
}).*;

pub fn main() void {
    print("{s}", .{result});
}

const raw_data = blk: {
    var it = std.mem.tokenizeSequence(u8, input, newline ++ newline);
    @setEvalBranchQuota(std.math.maxInt(u32));
    break :blk .{ .ordering_rules = it.next().?, .safety_manuals = it.next().? };
};

const OrderingRule = struct { l: u32, r: u32 };
const SafetyManual = []u32;
const Data = struct { ordering_rules: []const OrderingRule, safety_manuals: []const SafetyManual };
const data = blk: {
    @setEvalBranchQuota(std.math.maxInt(u32));
    var ordering_rules = std.mem.zeroes([count(u8, raw_data.ordering_rules, newline)]OrderingRule);
    var rules = std.mem.tokenizeAny(u8, raw_data.ordering_rules, "|" ++ newline);
    for (0..ordering_rules.len) |i| {
        @setEvalBranchQuota(std.math.maxInt(u32));
        ordering_rules[i] = OrderingRule{
            .l = parseInt(u32, rules.next().?, 10) catch unreachable,
            .r = parseInt(u32, rules.next().?, 10) catch unreachable,
        };
    }
    @setEvalBranchQuota(std.math.maxInt(u32));
    var safety_manuals = zeroes([count(u8, raw_data.safety_manuals, newline)]SafetyManual);
    var manuals = std.mem.tokenizeSequence(u8, raw_data.safety_manuals, newline);
    for (0..safety_manuals.len) |i| {
        var pages = std.mem.zeroes([count(u8, manuals.peek().?, ",") + 1]u32);
        var page = std.mem.tokenizeScalar(u8, manuals.next().?, ',');
        for (0..pages.len) |j| {
            pages[j] = parseInt(u32, page.next().?, 10) catch unreachable;
        }
        safety_manuals[i] = pages[0..];
    }

    break :blk Data{ .ordering_rules = ordering_rules[0..], .safety_manuals = &safety_manuals };
};

fn part1() usize {
    return blk: {
        var sum: u32 = 0;
        for (data.safety_manuals) |manual| {
            manuals: for (manual[0 .. manual.len - 1], 1..) |l, i| {
                for (manual[i..]) |r| {
                    @setEvalBranchQuota(std.math.maxInt(u32));
                    for (data.ordering_rules) |rule| {
                        // Rule applies and is ok
                        if (l == rule.l and r == rule.r) continue;
                        // Rule applies and is not ok, we can jump to the next manual
                        if (r == rule.l and l == rule.r) break :manuals;
                        // Implicit else -> rule does not apply -> continue
                    }
                }
            } else {
                // Else gets triggerd if we don't break out of the loop
                sum += manual[manual.len / 2];
            }
        }
        break :blk sum;
    };
}

fn lessThanFn(_: @TypeOf({}), l: u32, r: u32) bool {
    return for (data.ordering_rules) |rule| {
        if (r == rule.l and l == rule.r) break false;
    } else true;
}

fn part2() usize {
    return blk: {
        var sum: u32 = 0;
        for (data.safety_manuals) |manual| {
            manuals: for (manual[0 .. manual.len - 1], 1..) |l, i| {
                for (manual[i..]) |r| {
                    @setEvalBranchQuota(std.math.maxInt(u32));
                    for (data.ordering_rules) |rule| {
                        // If rule is broken, sort manual
                        if (r == rule.l and l == rule.r) {
                            var man: [manual.len]u32 = undefined;
                            for (0..man.len) |j| man[j] = manual[j];
                            std.sort.pdq(u32, &man, {}, comptime lessThanFn);
                            sum += man[man.len / 2];
                            break :manuals;
                        }
                    }
                }
            }
        }
        break :blk sum;
    };
}
