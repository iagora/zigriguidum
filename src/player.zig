const std = @import("std");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");
const am = @import("action.zig");
const gm = @import("game.zig");

pub const Player = struct {
    tokens: [5]u8, // Number of each type of gem tokens
    goldTokens: u8,
    purchasedCards: std.ArrayList(cm.DevelopmentCard),
    reservedCards: std.ArrayList(cm.DevelopmentCard),
    prestigePoints: u8,
    nobleTiles: std.ArrayList(nm.NobleTile),
    isAI: bool,

    pub fn create(isAI: bool, allocator: std.mem.Allocator) Player {
        const player = Player{
            .tokens = [5]u8{ 0, 0, 0, 0, 0 },
            .goldTokens = 0,
            .purchasedCards = std.ArrayList(cm.DevelopmentCard).init(allocator),
            .reservedCards = std.ArrayList(cm.DevelopmentCard).init(allocator),
            .prestigePoints = 0,
            .nobleTiles = std.ArrayList(nm.NobleTile).init(allocator),
            .isAI = isAI,
        };
        return player;
    }

    pub fn play(self: Player, gameState: gm.Game) am.Action {
        _ = gameState;
        _ = self;
        return am.Action.takeTokens([5]u8{ 1, 1, 1, 0, 0 });
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
