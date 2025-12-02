//! https://adventofcode.com/2025/day/2
const std = @import("std");
const log = std.log.scoped(.day02);

pub const std_options: std.Options = .{
    .log_level = .warn,
};

const Part = enum { one, two };

pub fn main() !void {
    const input = @embedFile("input/day02.txt");

    var result = try process(input, .one);
    log.warn("Part 1 result: {d}", .{result});
    result = try process(input, .two);
    log.warn("Part 2 result: {d}", .{result});
}

fn process(input: []const u8, part: Part) !usize {
    var iter = std.mem.splitAny(u8, std.mem.trim(u8, input, "\n"), "-,");

    var sum: usize = 0;

    while (iter.peek()) |_| {
        const start_raw = iter.next() orelse unreachable;
        const end_raw = iter.next() orelse return error.BadInput;
        const start = try std.fmt.parseInt(usize, start_raw, 10);
        const end = try std.fmt.parseInt(usize, end_raw, 10);
        for (start..end + 1) |num| {
            switch (part) {
                .one => {
                    if (isInvalid(num)) {
                        log.info("Found invalid: {d}", .{num});
                        sum += num;
                    }
                },
                .two => {
                    if (containsDuplicates(num)) {
                        log.info("Found one with duplicates: {d}", .{num});
                        sum += num;
                    }
                },
            }
        }
    }
    return sum;
}

fn isInvalid(num: usize) bool {
    var buf: [16]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch unreachable;
    // Odd number of digits are valid by default
    if (str.len & 0x01 != 0) return false;
    std.debug.assert(str.len & 0x01 == 0);

    const window_size = (str.len / 2);

    log.debug("Using window size {d}", .{window_size});
    var window = std.mem.window(u8, str, window_size, window_size);
    var previous: []const u8 = window.next() orelse unreachable;
    while (window.next()) |pane| {
        log.debug("Comparing: [{s}] ==? [{s}]", .{ previous, pane });
        if (std.mem.eql(u8, previous, pane)) {
            return true;
        }
        previous = pane;
    }
    return false;
}

fn containsDuplicates(num: usize) bool {
    var buf: [16]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch unreachable;
    const max_window_size = (str.len / 2) + 1;

    for (1..max_window_size) |window_size| next_window: {
        var window = std.mem.window(u8, str, window_size, window_size);
        var previous: []const u8 = window.next() orelse unreachable;
        while (window.next()) |pane| {
            defer previous = pane;

            log.debug("Comparing: [{s}] ==? [{s}]", .{ previous, pane });
            if (!std.mem.eql(u8, previous, pane)) {
                break :next_window;
            }
        }
        return true;
    }
    return false;
}

test "isInvalid" {
    std.testing.log_level = .debug;
    try std.testing.expect(isInvalid(1212));
    try std.testing.expect(isInvalid(11));
    try std.testing.expect(isInvalid(22));
    try std.testing.expect(isInvalid(1188511885));
    try std.testing.expect(isInvalid(38593859));

    try std.testing.expect(!isInvalid(10));
    try std.testing.expect(!isInvalid(23));
    try std.testing.expect(!isInvalid(1011));
    try std.testing.expect(!isInvalid(1289512894));
    try std.testing.expect(!isInvalid(1188511884));
}
test "containsDuplicates" {
    std.testing.log_level = .debug;
    try std.testing.expect(containsDuplicates(1212));
    try std.testing.expect(containsDuplicates(11));
    try std.testing.expect(containsDuplicates(22));
    try std.testing.expect(containsDuplicates(1188511885));
    try std.testing.expect(containsDuplicates(38593859));
    try std.testing.expect(containsDuplicates(1111));

    try std.testing.expect(!containsDuplicates(10));
    try std.testing.expect(!containsDuplicates(23));
    try std.testing.expect(!containsDuplicates(101));
    try std.testing.expect(!containsDuplicates(110));
    try std.testing.expect(!containsDuplicates(1011));
    try std.testing.expect(!containsDuplicates(1188511884));
    try std.testing.expect(!containsDuplicates(824824823));
    try std.testing.expect(!containsDuplicates(1289512894));
    try std.testing.expect(!containsDuplicates(1286515834));
}

const test_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";
test "part1" {
    std.testing.log_level = .info;

    const res = try process(test_input, .one);
    try std.testing.expectEqual(1227775554, res);
}
test "part2" {
    std.testing.log_level = .info;

    const res = try process(test_input, .two);
    try std.testing.expectEqual(4174379265, res);
}
