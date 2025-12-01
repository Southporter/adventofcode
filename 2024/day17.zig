const std = @import("std");
const log = std.log.scoped(.day17);
const BigInt = std.math.big.int.Managed;
const ConstInt = std.math.big.int.Const;

const Computer = struct {
    reg_a: BigInt,
    reg_b: BigInt,
    reg_c: BigInt,
    buf: BigInt,
    two: BigInt,
    allocator: std.mem.Allocator,

    instuctions: []const u3,
    ip: usize = 0,

    output: std.fs.File.Writer,
    output_first: bool = true,

    pub fn deinit(comp: *Computer) void {
        comp.reg_a.deinit();
        comp.reg_b.deinit();
        comp.reg_c.deinit();
        comp.buf.deinit();
        comp.two.deinit();
    }

    const Op = enum(u3) {
        adv = 0,
        bxl,
        bst,
        jnz,
        bxc,
        out = 5,
        bdv,
        cdv,
    };
    pub const Mode = enum {
        output,
        verify,
    };
    pub fn run(comp: *Computer, mode: Mode) !enum { done, invalid } {
        var validation_index: usize = 0;
        while (comp.ip < comp.instuctions.len) {
            const inst: Op = @enumFromInt(comp.instuctions[comp.ip]);
            // comp.debug();
            // log.debug("Instruction: {s} at {d}", .{ @tagName(inst), comp.ip });
            switch (inst) {
                .adv => {
                    const val = comp.getCombo(comp.ip + 1);

                    var bottom = try BigInt.init(comp.allocator);
                    defer bottom.deinit();
                    try bottom.pow(&comp.two, val.to(u32) catch unreachable);
                    try comp.reg_a.divTrunc(&comp.buf, &comp.reg_a, &bottom);
                    comp.ip += 2;
                },
                .bxl => {
                    const val = comp.instuctions[comp.ip + 1];
                    var temp = try BigInt.initSet(comp.allocator, val);
                    defer temp.deinit();
                    try comp.buf.bitXor(&comp.reg_b, &temp);
                    comp.reg_b.swap(&comp.buf);
                    comp.ip += 2;
                },
                .bst => {
                    const val = comp.getCombo(comp.ip + 1);
                    try comp.reg_b.truncate(&val, .unsigned, 3);
                    comp.ip += 2;
                },
                .jnz => {
                    if (!comp.reg_a.eqlZero()) {
                        const val = comp.instuctions[comp.ip + 1];
                        comp.ip = val;
                    } else {
                        comp.ip += 2;
                    }
                },
                .bxc => {
                    try comp.buf.bitXor(&comp.reg_b, &comp.reg_c);
                    comp.reg_b.swap(&comp.buf);
                    comp.ip += 2;
                },
                .out => {
                    switch (mode) {
                        .output => {
                            if (!comp.output_first) {
                                _ = try comp.output.write(",");
                            }
                            const val = comp.getCombo(comp.ip + 1);
                            try comp.buf.truncate(&val, .unsigned, 3);
                            try comp.output.print("{d}", .{comp.buf.to(u16) catch 888});
                            comp.output_first = false;
                        },
                        .verify => {
                            const val = comp.getCombo(comp.ip + 1);
                            if (validation_index >= comp.instuctions.len) return .invalid;
                            if ((val.to(u16) catch 888) != comp.instuctions[validation_index]) {
                                return .invalid;
                            }
                            validation_index += 1;
                        },
                    }
                    comp.ip += 2;
                },
                .bdv => {
                    const val = comp.getCombo(comp.ip + 1);

                    var bottom = try BigInt.init(comp.allocator);
                    defer bottom.deinit();
                    try bottom.pow(&comp.two, val.to(u32) catch unreachable);
                    try comp.reg_b.divTrunc(&comp.buf, &comp.reg_a, &bottom);
                    comp.ip += 2;
                },
                .cdv => {
                    defer comp.ip += 2;

                    const val = comp.getCombo(comp.ip + 1);

                    var bottom = try BigInt.init(comp.allocator);
                    defer bottom.deinit();
                    try bottom.pow(&comp.two, val.to(u32) catch unreachable);
                    try comp.reg_c.divTrunc(&comp.buf, &comp.reg_a, &bottom);
                },
            }
        }
        if (mode == .verify) {
            if (validation_index == comp.instuctions.len) {
                return .done;
            } else {
                return .invalid;
            }
        }
        return .done;
    }

    fn getCombo(comp: *Computer, operand: usize) BigInt {
        switch (comp.instuctions[operand]) {
            0...3 => |x| {
                comp.buf.set(x) catch unreachable;
                return comp.buf;
            },
            4 => return comp.reg_a,
            5 => return comp.reg_b,
            6 => return comp.reg_c,
            7 => unreachable,
        }
    }

    fn debug(comp: *Computer) void {
        log.debug("A: {d}", .{comp.reg_a.to(u64) catch 888});
        log.debug("B: {d}", .{comp.reg_b.to(u64) catch 888});
        log.debug("C: {d}", .{comp.reg_c.to(u64) catch 888});
    }
};

pub fn main() !void {
    var instructions = [_]u3{ 0, 1, 5, 4, 3, 0 };
    // var instructions = [_]u3{ 2, 4, 1, 5, 7, 5, 1, 6, 0, 3, 4, 1, 5, 5, 3, 0 };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            log.err("Deinit error: {any}", .{check});
        }
    }

    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    var comp = Computer{
        // .reg_a = try BigInt.initSet(allocator, 44374556),
        .reg_a = try BigInt.initSet(allocator, 729),
        .reg_b = try BigInt.init(allocator),
        .reg_c = try BigInt.init(allocator),
        .buf = try BigInt.init(allocator),
        .two = try BigInt.initSet(allocator, 2),
        .allocator = allocator,
        .instuctions = &instructions,
        .output = stdout,
    };
    defer comp.deinit();

    _ = try stdout.write("Part 1: ");
    _ = try comp.run(.output);
    _ = try stdout.write("\n");

    for (10_000_000..100_000_000) |i| {
        if (@mod(i, 100000) == 0) {
            try stdout.print("Running {d}\n", .{i});
        }
        comp.ip = 0;
        try comp.reg_a.set(i);
        try comp.reg_b.set(0);
        try comp.reg_c.set(0);
        const result = try comp.run(.verify);
        if (result == .done) {
            try stdout.print("\nPart 2: {d}\n", .{i});
            break;
        }
    }
}
