const std = @import("std");
const c = @import("cards.zig");
const n = @import("nobles.zig");

pub const Player = struct {
    tokens: [5]u8, // Number of each type of gem tokens
    goldTokens: u8,
    purchasedCards: std.ArrayList(c.DevelopmentCard),
    reservedCards: std.ArrayList(c.DevelopmentCard),
    prestigePoints: u8,
    nobleTiles: std.ArrayList(n.NobleTile),
};
