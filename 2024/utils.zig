const std = @import("std");
const log = std.log.scoped(.utils);

pub fn Matrix(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Int => {},
        else => @compileError("Matrix can only be if Int types"),
    }
    return struct {
        rows: usize,
        cols: usize,
        stride: usize,
        buf: []const u8,

        const Self = @This();

        pub fn init(buf: []const u8) Self {
            const cols = std.mem.indexOf(u8, buf, "\n").?;
            const stride = cols + 1;
            const rows = buf.len / stride;

            log.info("Have rows: {d} and cols: {d}", .{ rows, cols });
            return .{ .rows = rows, .cols = cols, .stride = stride, .buf = buf };
        }

        pub fn calcIndex(mat: Self, coord: Coord(T)) usize {
            std.debug.assert(mat.inBounds(coord));
            const row: usize = @intCast(coord.row);
            const col: usize = @intCast(coord.col);
            return row * mat.stride + col;
        }

        pub fn getCoord(mat: Self, index: usize) Coord(T) {
            return .{ .row = @as(T, @intCast(index / mat.stride)), .col = @as(T, @intCast(index % mat.stride)) };
        }

        pub fn get(mat: Self, coord: Coord(T)) u8 {
            std.debug.assert(mat.inBounds(coord));
            return mat.buf[mat.calcIndex(coord)];
        }

        pub inline fn rowInBounds(mat: Self, row: T) bool {
            return row >= 0 and row < mat.rows;
        }

        pub inline fn colInBounds(mat: Self, col: T) bool {
            return col >= 0 and col < mat.cols;
        }

        pub fn inBounds(mat: Self, coord: Coord(T)) bool {
            return mat.rowInBounds(coord.row) and mat.colInBounds(coord.col);
        }
    };
}

pub fn Coord(comptime T: type) type {
    return struct {
        row: T,
        col: T,
        const Self = @This();

        pub fn up(self: Self) Self {
            return .{ .row = self.row - 1, .col = self.col };
        }
        pub fn down(self: Self) Self {
            return .{ .row = self.row + 1, .col = self.col };
        }
        pub fn left(self: Self) Self {
            return .{ .row = self.row, .col = self.col - 1 };
        }
        pub fn right(self: Self) Self {
            return .{ .row = self.row, .col = self.col + 1 };
        }
    };
}
