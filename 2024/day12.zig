//! https://adventofcode.com/2024/day/12
const std = @import("std");
const utils = @import("utils.zig");
const Coord = utils.Coord(usize);
const Matrix = utils.Matrix(usize);
const log = std.log.scoped(.day12);

const easy_test_data =
    \\EEEEE
    \\EXXXX
    \\EEEEE
    \\EXXXX
    \\EEEEE
    \\
;
const test_data =
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
    \\
;

const actual_data = @embedFile("./data/day12.txt");
const data = actual_data;

const Region = struct {
    area: u64 = 0,
    perimeter: u64 = 0,
    edges: u64 = 0,
};

pub fn main() !void {
    var seen = [_]bool{false} ** data.len;
    var result1: u64 = 0;
    var result2: u64 = 0;

    const matrix = Matrix.init(data);
    for (data, 0..) |cell, index| {
        if (cell == '\n' or seen[index]) continue;

        const start = matrix.getCoord(index);
        var region = Region{};
        travelRegion(matrix, start, &seen, cell, &region);

        const cost = region.area * region.perimeter;
        log.debug("Got region {c}: Area {d} * Perimeter {d} = {d}", .{ cell, region.area, region.perimeter, cost });
        result1 += cost;
        log.debug("Region has {d} corners", .{region.edges});
        result2 += region.area * region.edges;
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d} (should be 1363682)\n", .{result1});
    try stdout.print("Part 2: {d} \n", .{result2});
}

const N = 0;
const E = 1;
const W = 2;
const S = 3;

fn travelRegion(matrix: Matrix, pos: Coord, visited: []bool, current: u8, region: *Region) void {
    if (matrix.get(pos) != current) return;

    const i = matrix.calcIndex(pos);
    if (visited[i]) return;
    visited[i] = true;

    var edges = [4]bool{ false, false, false, false };

    log.debug("Visiting region {c} at {any}", .{ current, pos });
    region.area += 1;
    if (pos.row > 0) {
        const north = pos.up();
        if (current == matrix.get(north)) {
            travelRegion(matrix, north, visited, current, region);
        } else {
            region.perimeter += 1;
            edges[N] = true;
        }
    } else {
        edges[N] = true;
        region.perimeter += 1;
    }
    if (pos.col > 0) {
        const west = pos.left();
        if (current == matrix.get(west)) {
            travelRegion(matrix, west, visited, current, region);
        } else {
            region.perimeter += 1;
            edges[W] = true;
        }
    } else {
        region.perimeter += 1;
        edges[W] = true;
    }
    if (pos.col < matrix.cols - 1) {
        const east = pos.right();
        if (current == matrix.get(east)) {
            travelRegion(matrix, east, visited, current, region);
        } else {
            region.perimeter += 1;
            edges[E] = true;
        }
    } else {
        region.perimeter += 1;
        edges[E] = true;
    }
    if (pos.row < matrix.rows - 1) {
        const south = pos.down();
        if (current == matrix.get(south)) {
            travelRegion(matrix, south, visited, current, region);
        } else {
            region.perimeter += 1;
            edges[S] = true;
        }
    } else {
        region.perimeter += 1;
        edges[S] = true;
    }

    if (edges[N] and edges[W]) region.edges += 1;
    if (edges[N] and edges[E]) region.edges += 1;
    if (edges[S] and edges[W]) region.edges += 1;
    if (edges[S] and edges[E]) region.edges += 1;

    // Check negative corners
    if (pos.row > 0 and pos.col > 0 and !edges[N] and !edges[W]) {
        const top_left = Coord{ .row = pos.row - 1, .col = pos.col - 1 };
        if (current != matrix.get(top_left)) region.edges += 1;
    }
    if (pos.row > 0 and pos.col < matrix.cols - 1 and !edges[N] and !edges[E]) {
        const top_right = Coord{ .row = pos.row - 1, .col = pos.col + 1 };
        if (current != matrix.get(top_right)) region.edges += 1;
    }
    if (pos.row < matrix.rows - 1 and pos.col > 0 and !edges[S] and !edges[W]) {
        const bottom_left = Coord{ .row = pos.row + 1, .col = pos.col - 1 };
        if (current != matrix.get(bottom_left)) region.edges += 1;
    }
    if (pos.row < matrix.rows - 1 and pos.col < matrix.cols - 1 and !edges[S] and !edges[E]) {
        const bottom_right = Coord{ .row = pos.row + 1, .col = pos.col + 1 };
        if (current != matrix.get(bottom_right)) region.edges += 1;
    }
}
