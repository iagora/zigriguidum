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
    }
};
