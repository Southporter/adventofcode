const std = @import("std");
const log = std.log.scoped(.day09);

const test_data = "2333133121414131402";

const actual_data = @embedFile("./data/day09.txt");
// const data = test_data;
const data = actual_data;

pub const std_options = .{
    .log_level = .info,
};

const EMPTY: u16 = std.math.maxInt(u16);

const Disk = struct {
    const DISK_SIZE: usize = 4096 * 1024;
    buffer: [DISK_SIZE]u16 = [_]u16{EMPTY} ** DISK_SIZE,
    len: usize = 0,

    pub fn init(disk: *Disk, files: []const u8) void {
        var is_free = false;
        var current_index: u16 = 0;

        for (files) |size| {
            var i: u8 = '0';
            while (i < size) : (i += 1) {
                if (is_free) {
                    disk.buffer[disk.len] = EMPTY;
                } else {
                    disk.buffer[disk.len] = current_index;
                }
                disk.len += 1;
            }
            is_free = !is_free;
            if (!is_free) {
                current_index += 1;
            }
        }
    }
    pub fn checksum(disk: *Disk) u64 {
        var result: u64 = 0;
        for (disk.buffer[0..disk.len], 0..) |id, i| {
            if (disk.buffer[i] == EMPTY) {
                break;
            }
            result += id * i;
        }
        return result;
    }
};

pub fn main() !void {
    const part1_result = part1(data);

    const part2_result = try part2(data);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{part1_result});
    try stdout.print("Part 2: {d}\n", .{part2_result});
}

fn part1(files: []const u8) u64 {
    var disk: Disk = .{};
    // var last_index = (files.len - 1) / 2;
    // if (files.len % 2 == 0) {
    //     last_index -= 1;
    // }
    disk.init(files);

    log.debug("Disk: {d}", .{disk.buffer[0..disk.len]});
    var end = disk.len - 1;
    for (0..disk.len) |i| {
        if (i > end) break;
        if (disk.buffer[i] == EMPTY) {
            disk.buffer[i] = disk.buffer[end];
            disk.buffer[end] = EMPTY;
            while (disk.buffer[end] == std.math.maxInt(u16)) {
                end -= 1;
            }
        }
    }
    log.debug("Compacted: {d}", .{disk.buffer[0..disk.len]});

    log.debug("Running checksum", .{});
    return disk.checksum();
}

const File = struct {
    size: u16,
    id: u16,

    pub fn format(
        self: File,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("F({d}-{d})", .{ self.id, self.size });
    }
};

fn part2(files: []const u8) !u64 {
    const allocator = std.heap.page_allocator;
    var disk = try std.ArrayList(File).initCapacity(allocator, data.len);

    var is_free = false;
    var id: u16 = 0;

    for (files) |size| {
        if (is_free) {
            try disk.append(File{ .size = size - '0', .id = EMPTY });
        } else {
            try disk.append(File{ .size = size - '0', .id = id });
            id += 1;
        }
        is_free = !is_free;
    }

    // Shuffle the files
    var end = disk.items.len - 1;
    outer: while (end > 1) : (end -= 1) {

        // compact empty slots
        var i: usize = 0;
        while (i <= disk.items.len - 2) {
            if (disk.items[i].id == EMPTY and disk.items[i + 1].id == EMPTY) {
                disk.items[i + 1].size += (disk.items[i].size);
                _ = disk.orderedRemove(i);
            } else {
                i += 1;
            }
        }

        if (disk.items[end].id == EMPTY) {
            continue;
        }

        log.debug("Moving {any}", .{disk.items[end]});
        log.debug("Files: {any}", .{disk.items});
        var first_empty: usize = 1;
        while (first_empty < end) : (first_empty += 1) {
            if (disk.items[first_empty].id != EMPTY) {
                continue;
            }

            const file = disk.items[end];
            const current_empty = disk.items[first_empty];

            if (current_empty.size == file.size) {
                disk.items[first_empty].id = file.id;
                disk.items[end].id = EMPTY;
                continue :outer;
            }
            if (current_empty.size > file.size) {
                log.debug("Found a smaller match: {d} {d}", .{ disk.items[end].id, disk.items[end].size });
                const old_file = disk.items[end];
                const new_file = File{
                    .id = old_file.id,
                    .size = old_file.size,
                };
                disk.items[end].id = EMPTY;

                const new_size = current_empty.size - file.size;
                disk.items[first_empty].size = new_size;

                try disk.insert(first_empty, new_file);
                log.debug("File after move: {d} {d}", .{ disk.items[first_empty].id, disk.items[first_empty].size });

                continue :outer;
            }
        }

        // @breakpoint();
        // const current_empty = disk.items[slot];
        // if (current_empty.id != EMPTY) {
        //     continue;
        // }
        // log.debug("Looking at empty slot: {d} {d}", .{ slot, current_empty.size });
        // var end = disk.items.len - 1;
        // while (end > slot) : (end -= 1) {
        //     if (disk.items[end].id == EMPTY) {
        //         continue;
        //     }
        //     if (disk.items[end].size == current_empty.size) {
        //         disk.items[slot].id = disk.items[end].id;
        //         disk.items[end].id = EMPTY;
        //         break;
        //     }
        //     if (disk.items[end].size < current_empty.size) {
        //         log.debug("Found a smaller match: {d} {d}", .{ disk.items[end].id, disk.items[end].size });
        //         const old_file = disk.items[end];
        //         const file = File{
        //             .id = old_file.id,
        //             .size = old_file.size,
        //         };
        //         disk.items[end].id = EMPTY;

        //         const new_size = current_empty.size - file.size;
        //         disk.items[slot].size = new_size;

        //         try disk.insert(slot, file);
        //         const new_file = disk.items[slot];
        //         log.debug("File after move: {d} {d}", .{ new_file.id, new_file.size });

        //         break;
        //     }
        // }
    }

    var i: usize = 0;
    var result: u64 = 0;
    for (disk.items) |file| {
        if (file.id == EMPTY) {
            i += file.size;
        } else {
            for (0..file.size) |_| {
                result += i * file.id;
                i += 1;
            }
        }
    }
    return result;
}
