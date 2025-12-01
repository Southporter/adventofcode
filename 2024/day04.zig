const std = @import("std");

const log = std.log.scoped(.day04);

const test_data =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;
const actual_data = @embedFile("./data/day04.txt");

// const data = test_data;
const data = actual_data;

fn transform(alloc: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var matrix = std.ArrayList([]const u8).init(alloc);

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        try matrix.append(line);
    }

    return matrix.toOwnedSlice();
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const matrix = try transform(allocator, data);

    const part1_result = part1(matrix);
    const part2_result = part2(matrix);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{part1_result});
    try stdout.print("Part 2: {d}\n", .{part2_result});
}

fn checkBackwards(input: [][]const u8, row: usize, col: usize) bool {
    return col >= 3 and std.mem.eql(u8, "SAM", input[row][col - 3 .. col]);
}

test "backwards" {
    var input = [_][]const u8{
        "SAMXXMSAMXSAMX",
        "MAMXXMSAMXSSMX",
        "MMMSXXMASM",
    };
    try std.testing.expect(!checkBackwards(&input, 0, 0));
    try std.testing.expect(checkBackwards(&input, 0, 3));
    try std.testing.expect(!checkBackwards(&input, 0, 4));
    try std.testing.expect(checkBackwards(&input, 0, 9));
    try std.testing.expect(checkBackwards(&input, 0, input[0].len - 1));
    try std.testing.expect(!checkBackwards(&input, 1, 3));
    try std.testing.expect(!checkBackwards(&input, 1, input[0].len - 1));

    try std.testing.expect(!checkBackwards(&input, 2, 5));
}

fn checkForwards(input: [][]const u8, row: usize, col: usize) bool {
    return col <= (input[row].len - 4) and std.mem.eql(u8, "XMAS", input[row][col .. col + 4]);
}

test "forwards" {
    var input = [_][]const u8{
        "XMASXXMAXMASXMAS",
        "XMAAXXMAXMASXMAX",
    };
    try std.testing.expect(checkForwards(&input, 0, 0));
    try std.testing.expect(!checkForwards(&input, 0, 3));
    try std.testing.expect(!checkForwards(&input, 0, 5));
    try std.testing.expect(checkForwards(&input, 0, 8));
    try std.testing.expect(checkForwards(&input, 0, input[0].len - 4));
    try std.testing.expect(!checkForwards(&input, 0, input[0].len - 1));
    try std.testing.expect(!checkForwards(&input, 1, 0));
    try std.testing.expect(!checkForwards(&input, 1, input[0].len - 4));
}

fn checkUp(input: [][]const u8, row: usize, col: usize) bool {
    return row >= 3 and input[row - 1][col] == 'M' and input[row - 2][col] == 'A' and input[row - 3][col] == 'S';
}

test "up" {
    var input = [_][]const u8{
        "SM",
        "AA",
        "MS",
        "XX",
        "MM",
        "XX",
        "AA",
        "SS",
        "MM",
        "XS",
        "SX",
        "AM",
        "MA",
        "XX",
    };
    try std.testing.expect(!checkUp(&input, 0, 0));
    try std.testing.expect(checkUp(&input, 3, 0));
    try std.testing.expect(!checkUp(&input, 5, 0));
    try std.testing.expect(!checkUp(&input, 9, 0));
    try std.testing.expect(checkUp(&input, input.len - 1, 0));

    try std.testing.expect(!checkUp(&input, 3, 1));
    try std.testing.expect(!checkUp(&input, input.len - 1, 1));
}

fn checkDown(input: [][]const u8, row: usize, col: usize) bool {
    return row <= (input.len - 4) and input[row + 1][col] == 'M' and input[row + 2][col] == 'A' and input[row + 3][col] == 'S';
}

test "down" {
    var input = [_][]const u8{
        "XX",
        "MA",
        "AS",
        "SX",
        "MM",
        "XX",
        "MA",
        "AS",
        "SM",
        "XS",
        "XX",
        "MM",
        "AA",
        "SX",
    };
    try std.testing.expect(checkDown(&input, 0, 0));
    try std.testing.expect(!checkDown(&input, 3, 0));
    try std.testing.expect(checkDown(&input, 5, 0));
    try std.testing.expect(!checkDown(&input, 9, 0));
    try std.testing.expect(checkDown(&input, input.len - 4, 0));

    try std.testing.expect(!checkDown(&input, 0, 1));
    try std.testing.expect(!checkDown(&input, input.len - 4, 1));
}

fn checkDiagonalNW(input: [][]const u8, row: usize, col: usize) bool {
    return row >= 3 and col >= 3 and input[row - 1][col - 1] == 'M' and input[row - 2][col - 2] == 'A' and input[row - 3][col - 3] == 'S';
}

test "diagonal NW" {
    var input = [_][]const u8{
        "SXMSSSAX",
        "MAAAMAAA",
        "MMMMMMMA",
        "XXXXXMXX",
    };
    try std.testing.expect(!checkDiagonalNW(&input, 3, 0));
    try std.testing.expect(checkDiagonalNW(&input, 3, 3));
    try std.testing.expect(!checkDiagonalNW(&input, 3, input[3].len - 2));
    try std.testing.expect(checkDiagonalNW(&input, 3, input[3].len - 1));
    try std.testing.expect(!checkDiagonalNW(&input, 0, input[3].len - 1));
}

fn checkDiagonalNE(input: [][]const u8, row: usize, col: usize) bool {
    return row >= 3 and col <= (input[row].len - 4) and input[row - 1][col + 1] == 'M' and input[row - 2][col + 2] == 'A' and input[row - 3][col + 3] == 'S';
}
test "diagonal NE" {
    var input = [_][]const u8{
        "XMASASAS",
        "MAAAAAAA",
        "MMAMMMAA",
        "XXXXXMAX",
    };

    try std.testing.expect(!checkDiagonalNE(&input, 0, 0));
    try std.testing.expect(checkDiagonalNE(&input, 3, 0));
    try std.testing.expect(checkDiagonalNE(&input, 3, 2));
    try std.testing.expect(!checkDiagonalNE(&input, 3, 3));
    try std.testing.expect(checkDiagonalNE(&input, 3, 4));
    try std.testing.expect(!checkDiagonalNE(&input, 3, input[3].len - 1));
}

fn checkDiagonalSW(input: [][]const u8, row: usize, col: usize) bool {
    return row <= (input.len - 4) and col >= 3 and input[row + 1][col - 1] == 'M' and input[row + 2][col - 2] == 'A' and input[row + 3][col - 3] == 'S';
}

test "diagonal SW" {
    var input = [_][]const u8{
        "XXMXSXAX",
        "MAMAMAMA",
        "MAMMMAMX",
        "SXSXSMXX",
    };
    try std.testing.expect(!checkDiagonalSW(&input, 0, 0));
    try std.testing.expect(checkDiagonalSW(&input, 0, 3));
    try std.testing.expect(!checkDiagonalSW(&input, 0, 5));
    try std.testing.expect(checkDiagonalSW(&input, 0, input[0].len - 1));
    try std.testing.expect(!checkDiagonalSW(&input, 3, input[3].len - 1));
    try std.testing.expect(!checkDiagonalSW(&input, 2, input[2].len - 1));
}

fn checkDiagonalSE(input: [][]const u8, row: usize, col: usize) bool {
    return row <= (input.len - 4) and col <= (input[row].len - 4) and input[row + 1][col + 1] == 'M' and input[row + 2][col + 2] == 'A' and input[row + 3][col + 3] == 'S';
}

test "diagonal SE" {
    var input = [_][]const u8{
        "XXMXXXAX",
        "MMMAMMMA",
        "MAAMMMAX",
        "SXSSSMSS",
    };
    try std.testing.expect(checkDiagonalSE(&input, 0, 0));
    try std.testing.expect(!checkDiagonalSE(&input, 0, 1));
    try std.testing.expect(!checkDiagonalSE(&input, 0, 3));
    try std.testing.expect(checkDiagonalSE(&input, 0, 4));
    try std.testing.expect(!checkDiagonalSE(&input, 0, input[0].len - 1));
}

fn checkDiagonal(input: [][]const u8, row: usize, col: usize) usize {
    var matches: usize = 0;
    if (checkDiagonalNW(input, row, col)) {
        log.debug("Found it NW", .{});
        matches += 1;
    }
    if (checkDiagonalNE(input, row, col)) {
        log.debug("Found it NE", .{});
        matches += 1;
    }
    if (checkDiagonalSW(input, row, col)) {
        log.debug("Found it SW", .{});
        matches += 1;
    }
    if (checkDiagonalSE(input, row, col)) {
        log.debug("Found it SE", .{});
        matches += 1;
    }
    return matches;
}

fn checkBoard(input: [][]const u8, row: usize, col: usize) usize {
    var matches: usize = 0;
    // Check backwards
    if (checkBackwards(input, row, col)) {
        log.debug("Found it backwards", .{});
        matches += 1;
    }
    if (checkForwards(input, row, col)) {
        log.debug("Found it forwards", .{});
        matches += 1;
    }
    if (checkUp(input, row, col)) {
        log.debug("Found it up", .{});
        matches += 1;
    }
    if (checkDown(input, row, col)) {
        log.debug("Found it down", .{});
        matches += 1;
    }

    matches += checkDiagonal(input, row, col);
    return matches;
}

fn part1(input: [][]const u8) usize {
    var count: usize = 0;
    for (0..input.len) |i| {
        const row = input[i];
        for (0..row.len) |j| {
            if (row[j] == 'X') {
                log.debug("Found X at {d},{d}", .{ i, j });
                count += checkBoard(input, i, j);
            }
        }
    }
    return count;
}

fn checkMASX(input: [][]const u8, row: usize, col: usize) bool {
    if (row < 1 or col < 1 or row > input.len - 2 or col > input[row].len - 2) {
        return false;
    }
    // M-M
    // -A-
    // S-S
    if (input[row - 1][col - 1] == 'M' and input[row - 1][col + 1] == 'M' and input[row + 1][col - 1] == 'S' and input[row + 1][col + 1] == 'S') {
        return true;
    }
    // M-S
    // -A-
    // M-S
    if (input[row - 1][col - 1] == 'M' and input[row - 1][col + 1] == 'S' and input[row + 1][col - 1] == 'M' and input[row + 1][col + 1] == 'S') {
        return true;
    }
    // S-S
    // -A-
    // M-M
    if (input[row - 1][col - 1] == 'S' and input[row - 1][col + 1] == 'S' and input[row + 1][col - 1] == 'M' and input[row + 1][col + 1] == 'M') {
        return true;
    }
    // S-M
    // -A-
    // S-M
    if (input[row - 1][col - 1] == 'S' and input[row - 1][col + 1] == 'M' and input[row + 1][col - 1] == 'S' and input[row + 1][col + 1] == 'M') {
        return true;
    }
    return false;
}

fn part2(input: [][]const u8) usize {
    var count: usize = 0;
    for (0..input.len) |i| {
        const row = input[i];
        for (0..row.len) |j| {
            if (row[j] == 'A') {
                log.debug("Found A at {d},{d}", .{ i, j });
                if (checkMASX(input, i, j)) {
                    count += 1;
                }
            }
        }
    }

    return count;
}
