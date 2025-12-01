const std = @import("std");
const log = std.log.scoped(.day11);

// const test_data = "0 1 10 99 999";
const test_data = "125 17";
const actual_data = "0 27 5409930 828979 4471 3 68524 170";
const data = actual_data;

const Line = std.AutoArrayHashMap(usize, usize);

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var line1 = Line.init(allocator);
    const line2 = Line.init(allocator);

    var iter = std.mem.tokenizeScalar(u8, data, ' ');
    while (iter.next()) |token| {
        const num = try std.fmt.parseInt(u64, token, 10);
        try line1.put(num, 1);
    }

    const stdout = std.io.getStdOut().writer();
    var read = line1;
    var write = line2;
    for (0..75) |i| {
        write.clearRetainingCapacity();
        try blink(&read, &write);

        //log.debug("Line after {d}: {d}", .{ i + 1, write[0..count] });
        if (i == 24) try stdout.print("Part 1: {d}\n", .{count(write)});

        const tmp = read;
        read = write;
        write = tmp;
    }

    try stdout.print("Part 2: {d}\n", .{count(read)});
}

fn count(map: Line) usize {
    var iter = map.iterator();
    var c: usize = 0;
    while (iter.next()) |entry| {
        c += entry.value_ptr.*;
    }
    return c;
}

fn split(num: u64, digits: u64) [2]u64 {
    std.debug.assert(digits == (std.math.log10(num) + 1));
    const half = std.math.pow(u64, 10, (digits / 2));
    const top = num / half;
    const bottom = num % half;
    return .{ top, bottom };
}
test "split" {
    try std.testing.expectEqual([2]u32{ 1, 2 }, split(12, 2));
    try std.testing.expectEqual([2]u32{ 253, 0 }, split(253000, 6));
    try std.testing.expectEqual([2]u32{ 10, 10 }, split(1010, 4));
    try std.testing.expectEqual([2]u32{ 20, 24 }, split(2024, 4));
    try std.testing.expectEqual([2]u32{ 12345, 6789 }, split(1234506789, 10));
}

fn blink(read: *Line, write: *Line) !void {
    var iter = read.iterator();
    while (iter.next()) |entry| {
        const num = entry.key_ptr.*;
        if (num == 0) {
            const current_1s = write.get(1) orelse 0;

            try write.put(1, current_1s + entry.value_ptr.*);
            continue;
        }
        const num_digits = std.math.log10(num) + 1;
        if (num_digits & 0x01 == 0) {
            const after = split(num, num_digits);
            var existing = write.get(after[0]) orelse 0;
            try write.put(after[0], existing + entry.value_ptr.*);

            existing = write.get(after[1]) orelse 0;
            try write.put(after[1], existing + entry.value_ptr.*);
            continue;
        }
        const next = num * 2024;
        const existing = write.get(next) orelse 0;
        try write.put(next, existing + entry.value_ptr.*);
    }
}
