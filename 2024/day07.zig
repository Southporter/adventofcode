const std = @import("std");

const log = std.log.scoped(.day07);

const test_data =
    \\190: 10 19
    \\180: 5 10 18
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

const actual_data = @embedFile("./data/day07.txt");
// const data = test_data;
const data = actual_data;

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var result1: u64 = 0;
    var result2: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var parts = std.mem.splitSequence(u8, line, ": ");
        const res_raw = parts.next().?;
        const res = try std.fmt.parseInt(u64, res_raw, 10);
        const operands_raw = parts.next().?;

        var operands: [16]u16 = undefined;
        var count: usize = 0;
        var operands_iter = std.mem.splitScalar(u8, operands_raw, ' ');
        while (operands_iter.next()) |op| {
            operands[count] = try std.fmt.parseInt(u16, op, 10);
            count += 1;
        }

        if (checkEquation(res, operands[0..count])) {
            result1 += res;
        }
        if (checkPart2(res, operands[1..count], 0, operands[0])) {
            result2 += res;
        }
    }

    log.warn("Result1: {}", .{result1});
    log.warn("Result2: {}", .{result2});
}

fn checkEquation(total: u64, nums: []u16) bool {
    var ops = std.bit_set.IntegerBitSet(16).initEmpty();
    const max = std.math.pow(u16, 2, @truncate(nums.len - 1));

    while (ops.mask < max) : (ops.mask += 1) {
        var current: u64 = nums[0];
        for (nums[1..], 0..) |num, i| {
            current = if (ops.isSet(i)) current + num else current * num;

            if (current > total) {
                break;
            }
        }
        if (current == total) {
            std.debug.print("Found a match: {d} = ", .{total});
            for (nums, 0..) |num, i| {
                const op_char: u8 = if (ops.isSet(i)) '+' else '*';
                std.debug.print("{d} {c} ", .{ num, op_char });
            }
            std.debug.print("\n", .{});
            return true;
        }
    }
    return false;
}

fn concat(a: u64, b: u64) u64 {
    var pow: u64 = 10;
    while (b >= pow) : (pow *= 10) {}
    return a * pow + b;
}

fn checkPart2(total: u64, nums: []const u16, index: usize, current: u64) bool {
    if (index == nums.len) return current == total;
    if (current > total) return false;

    return checkPart2(total, nums, index + 1, current + nums[index]) or checkPart2(total, nums, index + 1, current * nums[index]) or checkPart2(total, nums, index + 1, concat(current, nums[index]));
}
