const std = @import("std");

const allocator = std.heap.page_allocator;
const Id = ?usize;
const raw_data = if (1 == 0) "2333133121414131402" else @embedFile("9.input")[0 .. @embedFile("9.input").len - 1];

pub fn main() !void {
    const data = blk: {
        var lst = try std.ArrayList(u8).initCapacity(allocator, raw_data.len);
        for (0..raw_data.len) |i| {
            const num = try std.fmt.parseInt(u8, raw_data[i .. i + 1], 10);
            try lst.append(num);
        }
        if (lst.items.len & 1 == 1) try lst.append(0);
        break :blk lst;
    };
    defer data.deinit();

    const File = struct { size: usize, free: usize, id: usize };

    const list = blk: {
        var lst = std.ArrayList(File).init(allocator);
        var i: usize = 0;
        var id: usize = 0;
        while (i < data.items.len) : ({
            i += 2;
            id += 1;
        }) {
            try lst.append(File{ .size = data.items[i], .free = data.items[i + 1], .id = id });
        }
        break :blk lst;
    };
    defer list.deinit();

    const disk = disk: {
        var len: usize = 0;
        for (list.items) |file| len += file.size + file.free;

        const d = try allocator.alloc(?usize, len);
        var disk_index: usize = 0;
        for (list.items) |file| {
            for (0..file.size) |_| {
                d[disk_index] = file.id;
                disk_index += 1;
            }
            for (0..file.free) |_| {
                d[disk_index] = null;
                disk_index += 1;
            }
        }
        break :disk d;
    };
    defer allocator.free(disk);

    const checksum = blk: {
        var l: usize = 0;
        var r: usize = disk.len - 1;

        while (true) {
            while (disk[l] != null) l += 1;
            if (l >= r) break;
            while (disk[r] == null) r -= 1;
            disk[l] = disk[r];
            disk[r] = null;
        }

        var sum: usize = 0;
        for (disk, 0..) |b, i| {
            if (b) |id| sum += i * id;
        }

        break :blk sum;
    };

    const File2 = struct { size: std.ArrayList(Id), free: std.ArrayList(Id) };

    const disk2 = blk: {
        var d = std.ArrayList(File2).init(allocator);
        var i: usize = 0;
        var id: usize = 0;
        while (i < data.items.len) : ({
            i += 2;
            id += 1;
        }) {
            var size = std.ArrayList(Id).init(allocator);
            for (0..data.items[i]) |_| try size.append(id);
            var free = try std.ArrayList(Id).initCapacity(allocator, data.items[i + 1]);
            for (0..data.items[i + 1]) |_| try free.append(null);
            try d.append(File2{ .size = size, .free = free });
        }
        break :blk d;
    };
    defer {
        for (disk2.items) |file| {
            file.size.deinit();
            file.free.deinit();
        }
        disk2.deinit();
    }

    const checksum2 = blk: {
        var r = disk2.items.len - 1;
        while (0 < r) : (r -= 1) {
            const r_size_len = std.mem.count(Id, disk2.items[r].size.items, &[_]Id{disk2.items[r].size.items[0]});
            for (0..r) |l| {
                const l_free_len = std.mem.count(Id, disk2.items[l].free.items, &[_]Id{null});
                if (r_size_len <= l_free_len) {
                    const free_start = std.mem.indexOfScalar(Id, disk2.items[l].free.items, null) orelse continue;
                    for (0..r_size_len) |i| {
                        disk2.items[l].free.items[i + free_start] = disk2.items[r].size.items[i];
                        disk2.items[r].size.items[i] = null;
                    }
                }
            }
        }

        var sum: usize = 0;
        var index: usize = 0;
        for (disk2.items) |file| {
            for (file.size.items) |id| {
                if (id) |val| sum += index * val;
                index += 1;
            }
            for (file.free.items) |id| {
                if (id) |val| sum += index * val;
                index += 1;
            }
        }
        break :blk sum;
    };

    std.debug.print("{d} {d}\n", .{ checksum, checksum2 });
}
