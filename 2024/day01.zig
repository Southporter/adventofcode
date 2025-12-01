const std = @import("std");

const log = std.log.scoped(.day01);

const test_input =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
    \\
;
const actual_input = @embedFile("./data/day01.txt");
const input = actual_input;

const Pair = struct {
    x: isize,
    y: isize,
};

fn transform(alloc: std.mem.Allocator, in: []const u8) ![2][]isize {
    var iter = std.mem.splitScalar(u8, in, '\n');
    var output = std.MultiArrayList(Pair){};
    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        const first_space = std.mem.indexOf(u8, line, " ") orelse unreachable;
        const last_space = std.mem.lastIndexOf(u8, line, " ") orelse unreachable;
        const x = try std.fmt.parseInt(isize, line[0..first_space], 10);
        const y = try std.fmt.parseInt(isize, line[last_space + 1 ..], 10);
        try output.append(alloc, .{ .x = x, .y = y });
    }
    return .{ output.items(.x), output.items(.y) };
}

fn inputLen(comptime in: []const u8) usize {
    @setEvalBranchQuota(100000);
    var iter = std.mem.splitScalar(u8, in, '\n');
    var len: usize = 0;
    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        len += 1;
    }
    return len;
}

const BitSet = std.StaticBitSet(inputLen(input));

const Min = struct {
    index: usize,
    value: isize,
};

pub fn findMin(seen: BitSet, list: []isize) Min {
    var min: isize = std.math.maxInt(isize);
    var index: usize = 0;
    for (list, 0..) |val, i| {
        if (seen.isSet(i)) {
            continue;
        }
        if (val < min) {
            min = val;
            index = i;
        }
    }

    return .{ .index = index, .value = min };
}

pub fn part1(data: [2][]isize) !usize {
    var seenLeft = std.bit_set.StaticBitSet(inputLen(input)).initEmpty();
    var seenRight = std.bit_set.StaticBitSet(inputLen(input)).initEmpty();
    const total = data[0].len;
    var sum: usize = 0;
    for (0..total) |_| {
        const min_left = findMin(seenLeft, data[0]);
        const min_right = findMin(seenRight, data[1]);
        seenLeft.set(min_left.index);
        seenRight.set(min_right.index);
        sum += @abs(min_left.value - min_right.value);
    }
    return sum;
}

pub fn part2(data: [2][]isize) !usize {
    var sum: usize = 0;
    for (data[0]) |val| {
        var matches: usize = 0;
        for (data[1]) |val2| {
            if (val == val2) {
                matches += 1;
            }
        }
        const uval: usize = @intCast(val);
        sum += uval * matches;
    }
    return sum;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const data = try transform(allocator, input);

    const part1_sum = try part1(data);
    const part2_sum = try part2(data);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Sum for part 1 is: {d}\n", .{part1_sum});
    try stdout.print("Sum for part 2 is: {d}\n", .{part2_sum});
}
