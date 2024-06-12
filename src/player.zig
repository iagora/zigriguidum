const std = @import("std");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");

pub const Player = struct {
    tokens: [5]u8, // Number of each type of gem tokens
    goldTokens: u8,
    purchasedCards: std.ArrayList(cm.DevelopmentCard),
    reservedCards: std.ArrayList(cm.DevelopmentCard),
    prestigePoints: u8,
    nobleTiles: std.ArrayList(nm.NobleTile),
    isAI: bool,

    pub fn initialize(self: *Player, allocator: std.mem.Allocator) void {
        self.tokens = [5]u8{ 0, 0, 0, 0, 0 };
        self.goldTokens = 0;
        self.purchasedCards = std.ArrayList(cm.DevelopmentCard).init(allocator);
        self.reservedCards = std.ArrayList(cm.DevelopmentCard).init(allocator);
        self.prestigePoints = 0;
        self.nobleTiles = std.ArrayList(nm.NobleTile).init(allocator);
    }

    pub fn print(self: Player) void {
        std.debug.print("prestige: {}\ttokens: {any}\tgold: {}\n", .{ self.prestigePoints, self.tokens, self.goldTokens });
        std.debug.print("owned cards:\n", .{});
        for (self.purchasedCards.items) |card| {
            card.print();
        }
        std.debug.print("reserved cards:\n", .{});
        for (self.reservedCards.items) |card| {
            card.print();
        }
        std.debug.print("visiting nobles:\n", .{});
        for (self.nobleTiles.items) |noble| {
            std.debug.print("{s} -> 3 prestige\n", .{noble.name});
        }
        std.debug.print("\n", .{});
    }
};
