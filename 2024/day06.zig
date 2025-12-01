const std = @import("std");
const log = std.log.scoped(.day06);

const test_data =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

const actual_data = @embedFile("./data/day06.txt");

// const data = test_data;
const data = actual_data;

pub fn main() !void {
    var seen = [_]bool{false} ** data.len;
    const part1_result = part1(&seen);
    const part2_result = part2(&seen);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{part1_result});
    try stdout.print("Part 2: {d}\n", .{part2_result});
}

const Direction = enum(u8) {
    up = 0b0001,
    down = 0b0010,
    left = 0b0100,
    right = 0b1000,
};

fn outOfBounds(row: usize, col: usize, stride: usize, row_count: usize) bool {
    return row < 0 or col < 0 or row >= row_count or col >= stride;
}

pub fn part1(seen: []bool) usize {
    const map = Map.init(data);
    var guard = Guard.init(map);
    var total_tiles: usize = 0;

    while (true) {
        const gi = guard.row * map.stride + guard.col;
        if (gi < seen.len) {
            if (!seen[gi]) {
                total_tiles += 1;
            }
            seen[gi] = true;
        }
        guard.move(map) catch break;
    }

    return total_tiles;
}

const Map = struct {
    raw: []const u8,
    stride: usize,
    row_count: usize,

    pub fn init(raw: []const u8) Map {
        const stride = std.mem.indexOf(u8, raw, "\n").? + 1;
        const row_count = (raw.len / stride) + 1;
        log.debug("Total Rows: {}, Cols: {}", .{ row_count, stride });
        return .{ .raw = raw, .stride = stride, .row_count = row_count };
    }

    pub fn get(self: Map, row: usize, col: usize) u8 {
        const i = row * self.stride + col;
        if (i >= self.raw.len) {
            return '?';
        }
        return self.raw[i];
    }
};

const Guard = struct {
    row: usize,
    col: usize,
    direction: Direction,

    pub fn init(map: Map) Guard {
        const loc_raw = std.mem.indexOf(u8, map.raw, "^").?;
        const row = loc_raw / map.stride;
        const col = loc_raw % map.stride;
        return .{ .row = row, .col = col, .direction = .up };
    }

    pub fn move(self: *Guard, map: Map) !void {
        switch (self.direction) {
            .up => {
                if (self.row == 0) {
                    return error.OutOfBounds;
                }
                if (map.get(self.row - 1, self.col) == '#') {
                    self.turn();
                } else {
                    self.row -= 1;
                }
            },
            .down => {
                if (map.get(self.row + 1, self.col) == '#') {
                    self.turn();
                } else {
                    self.row += 1;
                    if (self.row == map.row_count) {
                        return error.OutOfBounds;
                    }
                }
            },
            .left => {
                if (self.col == 0) {
                    return error.OutOfBounds;
                }
                if (map.get(self.row, self.col - 1) == '#') {
                    self.turn();
                } else {
                    self.col -= 1;
                }
            },
            .right => {
                if (map.get(self.row, self.col + 1) == '#') {
                    self.turn();
                } else {
                    self.col += 1;
                    if (self.col == map.stride) {
                        return error.OutOfBounds;
                    }
                }
            },
        }
    }

    pub fn turn(self: *Guard) void {
        switch (self.direction) {
            .up => {
                self.direction = .right;
            },
            .down => {
                self.direction = .left;
            },
            .left => {
                self.direction = .up;
            },
            .right => {
                self.direction = .down;
            },
        }
    }
};

test "rotations" {
    const test_map =
        \\..#.
        \\#..#
        \\..^.
        \\.#..
    ;
    const map = Map.init(test_map);
    var guard = Guard.init(map);

    try std.testing.expectEqualDeep(Guard{ .row = 2, .col = 2, .direction = .up }, guard);

    try guard.move(map);
    try std.testing.expectEqualDeep(Guard{ .row = 1, .col = 2, .direction = .up }, guard);

    try guard.move(map);
    try std.testing.expectEqualDeep(Guard{ .row = 1, .col = 2, .direction = .right }, guard);

    try guard.move(map);
    try std.testing.expectEqualDeep(Guard{ .row = 1, .col = 2, .direction = .down }, guard);

    guard.row = 2;
    guard.col = 1;
    try guard.move(map);
    try std.testing.expectEqualDeep(Guard{ .row = 2, .col = 1, .direction = .left }, guard);
}
test "out of bounds" {
    const test_map =
        \\..#.
        \\#..#
        \\..^.
        \\.#..
    ;
    const map = Map.init(test_map);
    try std.testing.expectEqualDeep(Map{ .raw = test_map, .row_count = 4, .stride = 5 }, map);
    var guard = Guard.init(map);

    guard.row = 0;
    try std.testing.expectError(error.OutOfBounds, guard.move(map));

    guard.row = 3;
    guard.direction = .down;
    try std.testing.expectError(error.OutOfBounds, guard.move(map));

    guard.col = 0;
    guard.direction = .left;
    try std.testing.expectError(error.OutOfBounds, guard.move(map));

    guard.col = 4;
    guard.direction = .right;
    try std.testing.expectError(error.OutOfBounds, guard.move(map));
}
fn part2(seen: []bool) usize {
    var total_loops: usize = 0;
    log.debug("Seen: {any}", .{seen});

    var scratch = [_]u8{0} ** data.len;
    next_check: for (seen, 0..) |s, new_item| {
        if (s and data[new_item] != '^') {
            var directions = [_]u8{0} ** data.len;
            @memcpy(scratch[0..data.len], data);
            scratch[new_item] = '#';
            const map = Map.init(&scratch);
            log.debug("Checking with {}, {}", .{ new_item / map.stride, new_item % map.stride });

            var guard = Guard.init(map);

            while (true) {
                const i = guard.row * map.stride + guard.col;
                if (i >= seen.len) {
                    break;
                }
                switch (guard.direction) {
                    .up, .down => |dir| {
                        switch (scratch[i]) {
                            '-' => {
                                scratch[i] = '+';
                                directions[i] |= @intFromEnum(dir);
                            },
                            '+', '|' => {
                                if (directions[i] & @intFromEnum(dir) != 0) {
                                    total_loops += 1;
                                    continue :next_check;
                                }
                                directions[i] |= @intFromEnum(dir);
                            },
                            '.' => {
                                scratch[i] = '|';
                                directions[i] |= @intFromEnum(dir);
                            },
                            else => |char| {
                                log.err("Found an unexpected cell: {c}", .{char});
                            },
                        }
                    },
                    .left, .right => |dir| {
                        switch (scratch[i]) {
                            '|' => {
                                scratch[i] = '+';
                                directions[i] |= @intFromEnum(dir);
                            },
                            '+', '-' => {
                                if (directions[i] & @intFromEnum(dir) != 0) {
                                    total_loops += 1;
                                    continue :next_check;
                                }
                                directions[i] |= @intFromEnum(dir);
                            },
                            '.' => {
                                scratch[i] = '-';
                                directions[i] |= @intFromEnum(dir);
                            },
                            else => {
                                log.err("Found an unexpected cell: {c}", .{scratch[i]});
                            },
                        }
                    },
                }
                guard.move(map) catch {
                    if (data.ptr == test_data.ptr) {
                        for (0..map.row_count) |row| {
                            for (0..map.stride) |col| {
                                const index = row * map.stride + col;
                                if (index >= scratch.len) {
                                    std.debug.print("{c}", .{'?'});
                                } else {
                                    const char = scratch[index];
                                    std.debug.print("{c}", .{char});
                                }
                            }
                            std.debug.print("\n", .{});
                        }
                    }
                    continue :next_check;
                };
            }
        }
    }

    return total_loops;
}
