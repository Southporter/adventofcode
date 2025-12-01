const std = @import("std");
const log = std.log.scoped(.day14);
const utils = @import("utils.zig");
const Coord = utils.Coord(isize);

const Room = struct {
    width: u16,
    height: u16,

    pub fn findQuadrant(r: Room, pos: Position) ?Quadrant {
        const half_width = r.width / 2;
        const half_height = r.height / 2;
        const x = pos.x;
        const y = pos.y;
        if (pos.x == half_width or pos.y == half_height) return null;

        if (x < half_width) {
            if (y < half_height) {
                return Quadrant.BottomLeft;
            } else {
                return Quadrant.TopLeft;
            }
        } else {
            if (y < half_height) {
                return Quadrant.BottomRight;
            } else {
                return Quadrant.TopRight;
            }
        }
    }
};

const test_room = Room{ .width = 11, .height = 7 };

const test_data =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
;

const actual_room = Room{ .width = 101, .height = 103 };
const actual_data = @embedFile("./data/day14.txt");

const data = actual_data;
const room = actual_room;

pub fn main() !void {
    try part1();

    try part2();
}

fn part1() !void {
    var iter = std.mem.tokenizeScalar(u8, data, '\n');

    var quadrants = [4]u32{ 0, 0, 0, 0 };

    while (iter.next()) |bot| {
        log.debug("Bot: {s}", .{bot});
        var parts = std.mem.tokenizeScalar(u8, bot, ' ');
        const pos_raw = parts.next().?;
        var xy = std.mem.tokenizeScalar(u8, pos_raw[2..pos_raw.len], ',');
        const x = try std.fmt.parseInt(isize, xy.next().?, 10);
        const y = try std.fmt.parseInt(isize, xy.next().?, 10);

        const vel_raw = parts.next().?;
        xy = std.mem.tokenizeScalar(u8, vel_raw[2..vel_raw.len], ',');
        const dx = try std.fmt.parseInt(isize, xy.next().?, 10);
        const dy = try std.fmt.parseInt(isize, xy.next().?, 10);
        var robot = Robot{
            .pos = .{ .x = x, .y = y },
            .vel = .{ .dx = dx, .dy = dy },
        };
        robot.move(room, 100);
        log.debug("Bot after move is at {d},{d}", .{ robot.pos.x, robot.pos.y });

        if (room.findQuadrant(robot.pos)) |quad| {
            log.debug("Bot is in {any}", .{quad});
            quadrants[@intFromEnum(quad)] += 1;
        }
    }

    log.debug("Quads: {d}", .{quadrants});

    const result1: usize = quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{result1});
}
const Position = struct {
    x: isize,
    y: isize,
};

const Robot = struct {
    pos: Position,
    vel: struct {
        dx: isize,
        dy: isize,
    },

    pub fn move(self: *Robot, r: Room, seconds: isize) void {
        self.pos.x += self.vel.dx * seconds;
        self.pos.y += self.vel.dy * seconds;
        self.pos.x = @mod(@mod(self.pos.x, r.width) + r.width, r.width);
        self.pos.y = @mod(@mod(self.pos.y, r.height) + r.height, r.height);
    }
};

const Quadrant = enum(u4) {
    TopLeft = 0,
    TopRight,
    BottomLeft,
    BottomRight,
};

fn solve(start: Coord, dx: isize, dy: isize, seconds: u16) ?Quadrant {
    const end = Coord{ .row = start.row + (dx * seconds), .col = start.col + (dy * seconds) };
    return room.findQuadrant(end);
}

fn part2() !void {
    var iter = std.mem.tokenizeScalar(u8, data, '\n');

    var bots: [500]Robot = undefined;
    var i: usize = 0;

    while (iter.next()) |bot| {
        log.debug("Bot: {s}", .{bot});
        var parts = std.mem.tokenizeScalar(u8, bot, ' ');
        const pos_raw = parts.next().?;
        var xy = std.mem.tokenizeScalar(u8, pos_raw[2..pos_raw.len], ',');
        const x = try std.fmt.parseInt(isize, xy.next().?, 10);
        const y = try std.fmt.parseInt(isize, xy.next().?, 10);

        const vel_raw = parts.next().?;
        xy = std.mem.tokenizeScalar(u8, vel_raw[2..vel_raw.len], ',');
        const dx = try std.fmt.parseInt(isize, xy.next().?, 10);
        const dy = try std.fmt.parseInt(isize, xy.next().?, 10);
        const robot = Robot{
            .pos = .{ .x = x, .y = y },
            .vel = .{ .dx = dx, .dy = dy },
        };
        bots[i] = robot;
        i += 1;
    }
}
