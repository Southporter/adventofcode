const std = @import("std");
const utils = @import("./utils.zig");
const log = std.log.scoped(.day13);

pub const std_options = .{
    .log_level = .info,
};

const test_data =
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
;
const actual_data = @embedFile("./data/day13.txt");
const data = actual_data;

const COST_A: u8 = 3;
const COST_B: u8 = 1;

const Prize = struct {
    x: i64,
    y: i64,

    pub fn init(raw: []const u8) !Prize {
        var iter = std.mem.splitScalar(u8, raw, ' ');
        _ = iter.next(); // Prize
        const x_raw = iter.next().?;
        std.debug.assert(std.mem.eql(u8, x_raw[0..2], "X="));
        const x = try std.fmt.parseInt(i64, x_raw[2 .. x_raw.len - 1], 10);
        const y_raw = iter.next().?;
        std.debug.assert(std.mem.eql(u8, y_raw[0..2], "Y="));
        const y = try std.fmt.parseInt(i64, y_raw[2..], 10);
        return Prize{ .x = x, .y = y };
    }
};

const Button = struct {
    x: i64,
    y: i64,
    cost: u8 = 0,

    pub fn init(raw: []const u8, cost: u8) !Button {
        log.debug("Button raw: {s}", .{raw});
        var iter = std.mem.splitScalar(u8, raw, ' ');
        _ = iter.next(); // Button
        _ = iter.next(); // A or B
        const x_raw = iter.next().?;
        log.debug("x raw: {s} -> {s}", .{ x_raw, x_raw[2..] });
        std.debug.assert(std.mem.eql(u8, x_raw[0..2], "X+"));

        // Don't forget to trim the comma
        const x = try std.fmt.parseInt(i64, x_raw[2 .. x_raw.len - 1], 10);
        const y_raw = iter.next().?;
        std.debug.assert(std.mem.eql(u8, y_raw[0..2], "Y+"));
        const y = try std.fmt.parseInt(i64, y_raw[2..], 10);
        return Button{ .x = x, .y = y, .cost = cost };
    }
};
const Part2Offset: i64 = 10_000_000_000_000;

pub fn main() !void {
    var games = std.mem.splitSequence(u8, data, "\n\n");

    var result1: usize = 0;
    var result2: usize = 0;
    var i: usize = 1;
    while (games.next()) |game| {
        defer i += 1;

        const gameData = try Game.init(game);

        const cost1 = solve(gameData.button_a, gameData.button_b, gameData.prize);
        const cost2 = solve(gameData.button_b, gameData.button_a, Prize{
            .x = Part2Offset + gameData.prize.x,
            .y = Part2Offset + gameData.prize.y,
        });
        log.info("Cost for game {d}: {d} or {d}", .{ i, cost1, cost2 });
        result1 += cost1;
        result2 += cost2;
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{result1});
    try stdout.print("Part 2: {d}\n", .{result2});
}

const Game = struct {
    button_a: Button,
    button_b: Button,
    prize: Prize,

    pub fn init(raw: []const u8) !Game {
        var iter = std.mem.splitScalar(u8, raw, '\n');
        const button_a_details = iter.next().?;
        const button_a = try Button.init(button_a_details, COST_A);
        const button_b_details = iter.next().?;
        const button_b = try Button.init(button_b_details, COST_B);
        const prize_details = iter.next().?;
        const prize = try Prize.init(prize_details);
        return Game{ .button_a = button_a, .button_b = button_b, .prize = prize };
    }
};

fn solve(a: Button, b: Button, prize: Prize) u64 {
    // Cramer's rule'
    // We have two equations:
    //   a.x * press.a + b.x * press.b = prize.x
    //   a.y * press.a + b.y * press.b = prize.y
    //
    // A = | a.x b.x |
    //     | a.y b.y |
    //
    const det = a.x * b.y - a.y * b.x;

    // Substitute Prize in for A valus
    // Pa = | prize.x b.x |
    //      | prize.y b.y |
    const det_press_a = prize.x * b.y - prize.y * b.x;

    // Pb = | a.x prize.x |
    //      | a.y prize.y |
    const det_press_b = a.x * prize.y - a.y * prize.x;
    std.debug.assert(det != 0);

    const a_presses = @abs(@divTrunc(det_press_a, det));
    const b_presses = @abs(@divTrunc(det_press_b, det));

    if (@rem(det_press_a, det) == 0 and @rem(det_press_b, det) == 0) {
        log.info("Pressed a {d} times and b {d} times", .{ a_presses, b_presses });
        const cost = a.cost * a_presses + b.cost * b_presses;

        return cost;
    } else {
        return 0;
    }
}
