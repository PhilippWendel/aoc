const std = @import("std");

const data = @embedFile("2.data");

pub fn difference(l1: i32, l2: i32) i32 {
    return @max(l1, l2) - @min(l1, l2);
}

const Report = struct {
    list_of_levels: std.ArrayList(i32),

    fn init(self: Report) []i32 {
        const items = self.list_of_levels.items;
        return items[0..(items.len - 1)];
    }
    fn tail(self: Report) []i32 {
        return self.list_of_levels.items[1..];
    }

    fn increasing(self: Report) bool {
        return for (self.init(), self.tail()) |l, r| {
            if (!(l < r)) break false;
        } else true;
    }

    fn decreasing(self: Report) bool {
        return for (self.init(), self.tail()) |l, r| {
            if (!(l > r)) break false;
        } else true;
    }

    fn differ_least(self: Report, by: i32) bool {
        return for (self.init(), self.tail()) |l, r| {
            if (!(difference(l, r) >= by)) break false;
        } else true;
    }
    fn differ_most(self: Report, by: i32) bool {
        return for (self.init(), self.tail()) |l, r| {
            if (!(difference(l, r) <= by)) break false;
        } else true;
    }

    pub fn all_safe(s: Report) bool {
        return (s.increasing() or s.decreasing()) and
            s.differ_least(1) and
            s.differ_most(3);
    }
    pub fn safe(s: Report) !bool {
        if (s.all_safe()) return true;
        const items = s.list_of_levels.items;
        return for (0..items.len) |i| {
            var temp = try s.list_of_levels.clone();
            defer temp.deinit();
            _ = temp.orderedRemove(i);
            if ((Report{ .list_of_levels = temp }).all_safe()) break true;
        } else false;
    }
};

pub fn main() !void {
    // 1. Setup
    var reports = std.ArrayList(Report).init(std.heap.page_allocator);
    defer {
        for (reports.items) |report| {
            report.list_of_levels.deinit();
        }
        reports.deinit();
    }

    // 2. Parse
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        var it = std.mem.tokenizeAny(u8, line, " \r\n");
        var list_of_levels = std.ArrayList(i32).init(std.heap.page_allocator);
        errdefer list_of_levels.deinit();
        while (it.next()) |levels| {
            try list_of_levels.append((try std.fmt.parseInt(i32, levels, 10)));
        }
        try reports.append(.{ .list_of_levels = list_of_levels });
    }

    // 3. Compute safety
    const number_of_safe_reports = blk: {
        var sum: i32 = 0;
        for (reports.items) |report| {
            if (try report.safe()) sum += 1;
        }
        break :blk sum;
    };

    std.debug.print("Number of safe reports: {d}\n", .{number_of_safe_reports});
}
