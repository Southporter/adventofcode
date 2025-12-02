const std = @import("std");
const log = std.log.scoped(.day01);

pub fn main() !void {
    const input = @embedFile("input/day01.txt");
    const password = try partOne(input);
    log.info("Part 1 Password: {d}", .{password});
}

fn partOne(input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var password: usize = 0;
    var zero_clicks: usize = 0;
    var dial: WheelPoint = .init(50);

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        log.debug("Line: {s} -- Dial: {f}", .{ line, dial });
        const turn = try std.fmt.parseInt(u16, line[1..], 10);
        switch (line[0]) {
            'R' => {
                const clicks = dial.clicks(@intCast(turn));
                log.debug("Right Clicks: {d}", .{clicks});
                zero_clicks += clicks;
                dial = dial.right(turn);
            },
            'L' => {
                const iturns: i16 = @intCast(turn);
                const click_turns = -iturns;
                const clicks = dial.clicks(click_turns);
                log.debug("Left Clicks: {d}", .{clicks});
                zero_clicks += clicks;
                if (dial == .zero and click_turns < 0) {
                    zero_clicks -= 1;
                }
                dial = dial.left(turn);
                if (dial == .zero and click_turns < 0) {
                    zero_clicks += 1;
                }
            },
            else => return error.InvalidInput,
        }
        log.debug("Dial After: {f}", .{dial});
        if (dial == .zero) {
            password += 1;
        }
    }
    log.info("Part 2 password: {d}", .{zero_clicks});
    return password;
}

test "Part1" {
    std.testing.log_level = .debug;
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    try std.testing.expectEqual(3, try partOne(input));
}

const WheelPoint = enum(u8) {
    zero = 0,
    _,
    const total_dial_points = 100;

    fn init(val: u8) WheelPoint {
        if (val > total_dial_points) {
            return @enumFromInt(val % total_dial_points);
        }
        return @enumFromInt(val);
    }

    fn left(from: WheelPoint, turns: u16) WheelPoint {
        const current = @intFromEnum(from);
        const delta = turns % total_dial_points;
        if (current < delta) {
            const res = total_dial_points + current - delta;
            return @enumFromInt(res);
        } else {
            return @enumFromInt(current - delta);
        }
    }

    fn right(from: WheelPoint, turns: u16) WheelPoint {
        const current = @intFromEnum(from);
        return @enumFromInt((current + turns) % total_dial_points);
    }

    fn clicks(from: WheelPoint, turns: i16) u16 {
        return @abs(@divFloor(@intFromEnum(from) + turns, total_dial_points));
    }
    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        const as_int: u8 = @intFromEnum(self);
        return writer.print("{d}", .{as_int});
    }
};

test "turn left" {
    var test_val = WheelPoint.zero;

    try std.testing.expectEqual(WheelPoint.init(99), test_val.left(1));
    try std.testing.expectEqual(WheelPoint.init(1), test_val.right(1));
    try std.testing.expectEqual(WheelPoint.init(0), test_val.left(100));
    try std.testing.expectEqual(WheelPoint.init(0), test_val.right(100));
    try std.testing.expectEqual(WheelPoint.init(0), test_val.left(500));
    try std.testing.expectEqual(WheelPoint.init(0), test_val.right(500));
}
