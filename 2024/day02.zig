const std = @import("std");
const log = std.log.scoped(.day02);

const test_data =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

const actual_data = @embedFile("./data/day02.txt");
const data = actual_data;
// const data = test_data;

fn transform(alloc: std.mem.Allocator, input: []const u8) ![][]u16 {
    var iter = std.mem.splitScalar(u8, input, '\n');
    var output = std.ArrayList([]u16).init(alloc);

    var items = std.ArrayList(u16).init(alloc);
    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        log.debug("Processing line: {s}", .{line});
        var row_iter = std.mem.splitScalar(u8, line, ' ');
        var i: usize = 0;
        while (row_iter.next()) |cell| {
            const value = try std.fmt.parseInt(u16, cell, 10);
            try items.append(value);
            i += 1;
        }
        try output.append(try items.toOwnedSlice());
    }
    log.debug("Got {d} items", .{output.items.len});
    return output.items;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const input = try transform(allocator, data);

    const part1_result = try part1(input);
    const part2_result = try part2(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{part1_result});
    try stdout.print("Part 2: {d}\n", .{part2_result});
}

const Direction = enum {
    increase,
    decrease,
};

fn isSafe(row: []u16) bool {
    const direction: Direction = if (row[0] >= row[1]) .decrease else .increase;

    switch (direction) {
        .increase => {
            var left = row[0];
            for (row[1..]) |right| {
                if (left > right) {
                    return false;
                }
                const distance = right - left;
                if (distance > 3 or distance < 1) {
                    return false;
                }
                left = right;
            }
        },
        .decrease => {
            var left = row[0];
            for (row[1..]) |right| {
                if (left < right) {
                    return false;
                }
                const distance = left - right;
                if (distance > 3 or distance < 1) {
                    return false;
                }
                left = right;
            }
        },
    }
    return true;
}

fn part1(input: [][]u16) !usize {
    var safe_count: usize = 0;

    for (input) |row| {
        if (isSafe(row)) {
            safe_count += 1;
        }
    }
    return safe_count;
}

fn part2(input: [][]u16) !usize {
    var safe_count: usize = 0;

    outer: for (input) |row| {
        if (isSafe(row)) {
            safe_count += 1;
        } else {
            for (0..row.len) |i| {
                var buf: [10]u16 = undefined;
                const end = row.len - 1;
                @memcpy(buf[0..i], row[0..i]);
                @memcpy(buf[i..end], row[i + 1 ..]);
                log.debug("Row after removing one: {any}", .{buf[0..end]});
                if (isSafe(buf[0..end])) {
                    safe_count += 1;
                    continue :outer;
                }
            }
        }
    }
    return safe_count;
}
