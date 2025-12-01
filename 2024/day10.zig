const std = @import("std");
const utils = @import("./utils.zig");

const Coord = utils.Coord(usize);
const Matrix = utils.Matrix(usize);

const log = std.log.scoped(.day10);

const easy_test_data =
    \\0123
    \\1234
    \\8765
    \\9876
    \\
;
const test_data =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
    \\
;
const actual_data = @embedFile("./data/day10.txt");
const data = actual_data;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const matrix = Matrix.init(data);

    var result1: u64 = 0;
    var result2: u64 = 0;

    var nines = NinesMap.init(allocator);
    for (data, 0..) |cell, index| {
        if (cell == '0') {
            defer nines.clearRetainingCapacity();

            const coord = matrix.getCoord(index);
            log.debug("Found tail head: {any}", .{coord});
            const rating = try calcTrails(matrix, coord, '1', &nines);
            const score = nines.count();
            log.debug("Found {d} nines", .{score});
            log.debug("Rating is {d}", .{rating});
            result1 += score;
            result2 += rating;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d} (should be 698)\n", .{result1});
    try stdout.print("Part 2: {d}\n", .{result2});
}

const NinesMap = std.AutoHashMap(Coord, void);

fn calcTrails(matrix: Matrix, current_pos: Coord, next: u8, found_nines: *NinesMap) !usize {
    if (next == ('9' + 1)) {
        log.debug("Found 9 at {any}", .{current_pos});
        try found_nines.put(current_pos, {});
        return 1;
    }

    const row_start = current_pos.row -| 1;
    const row_end = @min(current_pos.row + 1, matrix.rows - 1);
    const col_start = current_pos.col -| 1;
    const col_end = @min(current_pos.col + 1, matrix.cols - 1);

    var rating: usize = 0;
    const north = Coord{ .row = row_start, .col = current_pos.col };
    if (matrix.get(north) == next) {
        rating += try calcTrails(matrix, north, next + 1, found_nines);
    }
    const south = Coord{ .row = row_end, .col = current_pos.col };
    if (matrix.get(south) == next) {
        rating += try calcTrails(matrix, south, next + 1, found_nines);
    }
    const east = Coord{ .row = current_pos.row, .col = col_end };
    if (matrix.get(east) == next) {
        rating += try calcTrails(matrix, east, next + 1, found_nines);
    }
    const west = Coord{ .row = current_pos.row, .col = col_start };
    if (matrix.get(west) == next) {
        rating += try calcTrails(matrix, west, next + 1, found_nines);
    }

    return rating;
}
