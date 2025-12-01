const std = @import("std");
const log = std.log.scoped(.day05);

const test_data =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

const actual_data = @embedFile("./data/day05.txt");

// const data = test_data;
const data = actual_data;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var parts = std.mem.splitSequence(u8, data, "\n\n");
    const rules_raw = parts.next() orelse unreachable;
    const pages = parts.next() orelse unreachable;

    var rules = std.ArrayList([2]u16).init(allocator);

    var rules_iter = std.mem.splitScalar(u8, rules_raw, '\n');
    while (rules_iter.next()) |line| {
        var rule = try rules.addOne();
        var rule_iter = std.mem.splitScalar(u8, line, '|');
        rule[0] = try std.fmt.parseInt(u16, rule_iter.next() orelse unreachable, 10);
        rule[1] = try std.fmt.parseInt(u16, rule_iter.next() orelse unreachable, 10);
    }

    // const part1_result = try part1(rules.items, pages);
    const part2_result = try part2(rules.items, pages);

    const stdout = std.io.getStdOut().writer();
    // try stdout.print("Part 1: {d}\n", .{part1_result});
    try stdout.print("Part 2: {d}\n", .{part2_result});
}

fn part1(rules: []const [2]u16, pages: []const u8) !usize {
    var section_iter = std.mem.splitScalar(u8, pages, '\n');
    var sum: usize = 0;

    var buf: [32]u16 = undefined;

    next_section: while (section_iter.next()) |section| {
        if (section.len == 0) {
            continue;
        }

        var page_iter = std.mem.splitScalar(u8, section, ',');
        var page_count: usize = 0;
        while (page_iter.next()) |page_num| {
            const page = try std.fmt.parseInt(u16, page_num, 10);
            buf[page_count] = page;
            page_count += 1;
        }
        log.debug("Pages: {any}", .{buf[0..page_count]});

        for (rules) |rule| {
            log.debug("Checking rule: {any}", .{rule});
            const first = std.mem.indexOf(u16, buf[0..page_count], rule[0..1]);
            if (first) |f| {
                const second = std.mem.indexOf(u16, buf[0..page_count], rule[1..2]);
                if (second) |s| {
                    log.debug("Found both pages: {d}, {d}", .{ f, s });
                    if (f > s) {
                        continue :next_section;
                    }
                }
            }
        }
        sum += buf[page_count / 2];
    }
    return sum;
}

fn fixPages(pages: []u16, rules: []const [2]u16) void {
    var passes: usize = 0;
    while (passes < 32) : (passes += 1) {
        log.debug("Pass {d}", .{passes});
        var is_fixed = true;
        for (rules) |rule| {
            const first = std.mem.indexOf(u16, pages, rule[0..1]);
            if (first) |f| {
                const second = std.mem.indexOf(u16, pages, rule[1..2]);
                if (second) |s| {
                    if (f > s) {
                        const temp = pages[f];
                        pages[f] = pages[s];
                        pages[s] = temp;
                        is_fixed = false;
                    }
                }
            }
        }
        if (is_fixed) {
            return;
        }
    }
    log.err("Failed to fix pages", .{});
    return;
}

fn part2(rules: []const [2]u16, pages: []const u8) !usize {
    var section_iter = std.mem.splitScalar(u8, pages, '\n');
    var sum: usize = 0;

    var buf: [32]u16 = undefined;

    while (section_iter.next()) |section| {
        if (section.len == 0) {
            continue;
        }

        var page_iter = std.mem.splitScalar(u8, section, ',');
        var page_count: usize = 0;
        while (page_iter.next()) |page_num| {
            const page = try std.fmt.parseInt(u16, page_num, 10);
            buf[page_count] = page;
            page_count += 1;
        }
        log.debug("Pages: {any}", .{buf[0..page_count]});

        rules_check: for (rules) |rule| {
            // log.debug("Checking rule: {any}", .{rule});
            const first = std.mem.indexOf(u16, buf[0..page_count], rule[0..1]);
            if (first) |f| {
                const second = std.mem.indexOf(u16, buf[0..page_count], rule[1..2]);
                if (second) |s| {
                    // log.debug("Found both pages: {d}, {d}", .{ f, s });
                    if (f > s) {
                        fixPages(buf[0..page_count], rules);
                        sum += buf[page_count / 2];
                        break :rules_check;
                    }
                }
            }
        }
    }
    return sum;
}
