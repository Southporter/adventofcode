const std = @import("std");
const log = std.log.scoped(.day03);

const test_data =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
;

const part2_test_data =
    \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
;

const actual_data = @embedFile("./data/day03.txt");

// const data = test_data;
// const data = part2_test_data;
const data = actual_data;

pub fn main() !void {
    // const part1_result = try part1();
    const part2_result = try part2();

    const stdout = std.io.getStdOut().writer();
    // try stdout.print("Part 1: {d}\n", .{part1_result});
    try stdout.print("Part 2: {d}\n", .{part2_result});
}

fn part1() !usize {
    var sum: usize = 0;
    var i: usize = 0;
    while (i < data.len - 4) : (i += 1) {
        if (std.mem.eql(u8, data[i .. i + 4], "mul(")) {
            log.debug("Found a multiply at {d}", .{i});
            i += 4;
            var first_num: usize = i;
            while (std.ascii.isDigit(data[first_num])) : (first_num += 1) {}
            log.debug("First number: {s}", .{data[i..first_num]});
            if (first_num == i) {
                log.debug("No first number. Continuing.", .{});
                continue;
            }
            if (data[first_num] != ',') {
                log.debug("Expected a comma but found: {s}", .{data[first_num .. first_num + 1]});
                continue;
            }
            const left = try std.fmt.parseInt(usize, data[i..first_num], 10);
            i = first_num + 1;
            var second_num: usize = first_num + 1;

            while (std.ascii.isDigit(data[second_num])) : (second_num += 1) {}
            log.debug("Second number: {s}", .{data[i..second_num]});
            if (second_num == i) {
                continue;
            }

            if (data[second_num] != ')') {
                continue;
            }
            const right = try std.fmt.parseInt(usize, data[i..second_num], 10);
            i = second_num;
            sum += left * right;
        }
    }

    return sum;
}

const dont_keyword = "don't()";
const do_keyword = "do()";

fn part2() !usize {
    var sum: usize = 0;
    var i: usize = 0;
    var is_enabled = true;
    while (i < data.len - dont_keyword.len) : (i += 1) {
        if (std.mem.eql(u8, data[i..(i + dont_keyword.len)], dont_keyword)) {
            log.debug("Found a don't at {d}", .{i});
            is_enabled = false;
            i += dont_keyword.len - 1;
            continue;
        }
        if (std.mem.eql(u8, data[i..(i + do_keyword.len)], do_keyword)) {
            log.debug("Found a do at {d}", .{i});
            is_enabled = true;
            i += do_keyword.len - 1;
            continue;
        }

        if (is_enabled and std.mem.eql(u8, data[i .. i + 4], "mul(")) {
            i += 4;
            var first_num: usize = i;
            while (std.ascii.isDigit(data[first_num])) : (first_num += 1) {}
            log.debug("First number: {s}", .{data[i..first_num]});
            if (first_num == i) {
                log.debug("No first number. Continuing.", .{});
                continue;
            }
            if (data[first_num] != ',') {
                log.debug("Expected a comma but found: {s}", .{data[first_num .. first_num + 1]});
                continue;
            }
            const left = try std.fmt.parseInt(usize, data[i..first_num], 10);
            i = first_num + 1;
            var second_num: usize = first_num + 1;

            while (std.ascii.isDigit(data[second_num])) : (second_num += 1) {}
            log.debug("Second number: {s}", .{data[i..second_num]});
            if (second_num == i) {
                log.debug("No first number. Continuing.", .{});
                continue;
            }

            if (data[second_num] != ')') {
                log.debug("Expected a ) but found: {s}", .{data[second_num .. second_num + 1]});
                continue;
            }
            const right = try std.fmt.parseInt(usize, data[i..second_num], 10);
            i = second_num;
            log.info("{d} * {d} = {d}", .{ left, right, left * right });
            sum += left * right;
        }
    }

    return sum;
}
