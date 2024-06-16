const std = @import("std");
const pm = @import("player.zig");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");
const am = @import("action.zig");

pub const Game = struct {
    players: []pm.Player,
    gemTokens: [5]u8, // Available gem tokens in the bank
    goldTokens: u8,
    developmentCards: []std.ArrayList(cm.DevelopmentCard), // 3 tiers of cards
    nobleTiles: std.ArrayList(nm.NobleTile),
    round: u16,

    pub fn initialize(players: []pm.Player, allocator: std.mem.Allocator) !Game {
        // Initialize gem tokens
        const tokenCount: u8 = switch (players.len) {
            2 => 4,
            3 => 5,
            else => 7,
        };
        // Initialize game state
        return Game{ .players = players, .gemTokens = [5]u8{ tokenCount, tokenCount, tokenCount, tokenCount, tokenCount }, .goldTokens = 5, .developmentCards = try cm.initialize(allocator), .nobleTiles = try nm.initialize(players.len, allocator), .round = 0 };
    }

    fn takeTokens(self: *Game, player: *pm.Player, tokens: [5]u8) !void {
        // Logic for taking tokens
        // Count the number of tokens being taken
        var totalRequested: u8 = 0;
        for (tokens) |t| {
            totalRequested += t;
        }

        // Calculate the player's current total tokens
        var playerTotal: u8 = 0;
        for (player.tokens) |t| {
            playerTotal += t;
        }

        // Ensure the action is valid
        if (playerTotal + totalRequested > 10) {
            return error.InvalidMove; // Cannot exceed 10 tokens
        }

        if (totalRequested > 3) {
            return error.InvalidMove; // Cannot take more than 3 tokens
        }

        var differentColors: u8 = 0;
        var sameColorCount: u8 = 0;
        for (0..5) |index| {
            if (tokens[index] > 0) {
                differentColors += 1;
                if (tokens[index] == 2) {
                    if (self.gemTokens[index] < 4) {
                        return error.InvalidMove; // Cannot take 2 tokens from a color with less than 4 tokens
                    }
                    sameColorCount += 1;
                }
            }
        }

        if (differentColors > 3) {
            return error.InvalidMove; // Cannot take more than 3 different colors
        }

        if (sameColorCount > 1 or (sameColorCount == 1 and totalRequested > 2)) {
            // Cannot take 2 tokens from more than one color or take more than 2 tokens of the same color
            return error.InvalidMove;
        }

        // Check for sufficient tokens in the bank
        for (0..5) |index| {
            if (tokens[index] > self.gemTokens[index]) {
                return error.InsufficientTokens; // Not enough tokens in the bank
            }
        }

        // Perform the action
        for (0..5) |index| {
            if (tokens[index] > 0) {
                self.gemTokens[index] -= tokens[index];
                player.tokens[index] += tokens[index];
            }
        }
    }

    fn reserveCard(self: *Game, player: *pm.Player, cardID: u128) !void {
        // Logic for reserving a card
        // Ensure the action is valid
        var cIdx: usize = undefined;
        var card: cm.DevelopmentCard = undefined;
        blk: for (0..3) |t| {
            for (self.developmentCards[t].items, 0..) |devCard, idx| {
                if (devCard.id == cardID) {
                    cIdx = idx;
                    card = devCard;
                    break :blk;
                }
            }
        }
        // Reserve the card
        try player.reservedCards.append(card);

        // Remove the card from the grid
        _ = self.developmentCards[card.tier - 1].orderedRemove(cIdx);

        // Give the player a gold token if available
        if (self.goldTokens > 0) {
            self.goldTokens -= 1;
            player.goldTokens += 1;
        }
    }

    fn purchaseCard(self: *Game, player: *pm.Player, cardID: u128) !void {
        // Logic for purchasing a card
        // Select the card from the appropriate source
        var fromReserve: bool = false;
        var cIdx: usize = undefined;
        const card: cm.DevelopmentCard = blk: {
            for (player.reservedCards.items, 0..) |card, idx| {
                if (card.id == cardID) {
                    cIdx = idx;
                    fromReserve = true;
                    break :blk card;
                }
            }
            for (0..3) |t| {
                for (self.developmentCards[t].items, 0..) |devCard, idx| {
                    if (devCard.id == cardID) {
                        cIdx = idx;
                        break :blk devCard;
                    }
                }
            }
            return error.CardNotFound;
        };

        // Calculate the cost after considering player's gem bonuses
        var remainingCost = card.cost;
        for (player.purchasedCards.items) |pCard| {
            remainingCost[@intFromEnum(pCard.gemBonus)] -|= 1; // saturated subtraction so I can keep the unsigned int
        }

        // Check if the player has enough tokens (including gold tokens)
        var totalTokensNeeded: u8 = 0;
        for (0..5) |index| {
            if (player.tokens[index] < remainingCost[index]) {
                totalTokensNeeded += remainingCost[index] - player.tokens[index];
            }
        }
        if (totalTokensNeeded > player.goldTokens) return error.InsufficientTokens;

        // Deduct the tokens from the player and add them back to the bank
        for (0..5) |index| {
            var needed = remainingCost[index];
            if (player.tokens[index] >= needed) {
                player.tokens[index] -= needed;
                self.gemTokens[index] += needed;
            } else {
                self.gemTokens[index] += player.tokens[index];
                needed -= player.tokens[index];
                player.tokens[index] = 0;
                player.goldTokens -= needed;
                self.goldTokens += needed;
            }
        }

        // Add the card to the player's purchased cards
        try player.purchasedCards.append(card);
        player.prestigePoints += card.prestigePoints;

        // Remove the card from the appropriate source
        if (fromReserve) {
            _ = player.reservedCards.orderedRemove(cIdx);
        } else {
            _ = self.developmentCards[card.tier - 1].orderedRemove(cIdx);
        }
    }

    fn checkNobleTiles(self: *Game, player: *pm.Player, pNumber: usize) !void {
        // Check if player can claim any noble tiles
        var bonusCount = [5]u8{ 0, 0, 0, 0, 0 };

        // Count the number of each type of gem bonus from purchased cards
        for (player.purchasedCards.items) |pCard| {
            bonusCount[@intFromEnum(pCard.gemBonus)] += 1;
        }

        // Check if the player meets the requirements for any noble tile
        for (self.nobleTiles.items, 0..) |tile, index| {
            var canClaim = true;
            for (0..5) |colorIndex| {
                if (bonusCount[colorIndex] < tile.requirements[colorIndex]) {
                    canClaim = false;
                    break;
                }
            }
            if (canClaim) {
                // pm.Player claims the noble tile
                try player.nobleTiles.append(tile);
                player.prestigePoints += tile.prestigePoints;

                // Remove the claimed noble tile from the game
                _ = self.nobleTiles.orderedRemove(index);

                std.debug.print("Player {} earned a visit from {s}\n\n", .{ pNumber, tile.name });

                return; // TODO: this should trigger player choice of noble
            }
        }
    }

    pub fn isGameOver(self: *Game) bool {
        for (self.players) |p| {
            if (p.prestigePoints >= 15) {
                return true;
            }
        }
        if (self.round > 0) std.debug.print("End: Round {}.\n\n", .{self.round});
        self.round += 1;
        return false;
    }

    pub fn generateGameState(self: Game, allocator: std.mem.Allocator) !Game {
        var gs = Game{
            .players = self.players,
            .gemTokens = self.gemTokens,
            .goldTokens = self.goldTokens,
            .developmentCards = try allocator.alloc(std.ArrayList(cm.DevelopmentCard), 3),
            .nobleTiles = self.nobleTiles,
            .round = self.round,
        };
        for (0..3) |t| {
            var deck = std.ArrayList(cm.DevelopmentCard).init(allocator);
            fblk: for (self.developmentCards[t].items, 0..) |card, idx| {
                try deck.append(card);
                if (idx >= 3) break :fblk;
            }
            gs.developmentCards[t] = deck;
        }

        return gs;
    }

    pub fn print(self: Game) void {
        std.debug.print("Begin: Round {}\n\n", .{self.round});
        std.debug.print("\tNobles:", .{});
        for (self.nobleTiles.items) |noble| {
            std.debug.print("\t{any}", .{noble.requirements});
        }
        std.debug.print("\n\tGem Tokens: {any}\tGold Tokens: {}\n\n", .{ self.gemTokens, self.goldTokens });
        // Reveal cards for each tier
        for (0..3) |t| {
            std.debug.print("Tier {}:\n", .{t + 1});
            for (self.developmentCards[t].items) |card| {
                card.print();
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn turn(self: *Game, action: am.Action, player: *pm.Player) !void {
        // Example turn sequence:
        // In a real game, you would take input from the player
        // Here, we'll simulate a simple token-taking action for demonstration
        const pNumber = blk: {
            for (self.players, 1..) |p, idx| {
                if (player.id == p.id) break :blk idx;
            }
            return error.PlayerNotFound;
        };

        switch (action.actionType) {
            am.ActionType.TakeTokens => {
                // Simulate taking 3 different tokens
                try self.takeTokens(player, action.tokens);
                std.debug.print("Player {} took {any} tokens\n\n", .{ pNumber, action.tokens });
            },
            am.ActionType.ReserveCard => {
                // Simulate reserving a card from tier 1, index 0
                try self.reserveCard(player, action.cardID.?);
                std.debug.print("Player {} reserved a card\n\n", .{pNumber});
            },
            am.ActionType.PurchaseCard => {
                // Simulate purchasing a card from tier 1, index 0
                const fromReserve = false;
                try self.purchaseCard(player, action.cardID.?);
                if (fromReserve) {
                    std.debug.print("Player {} bought a card from reserve\n\n", .{pNumber});
                } else {
                    std.debug.print("Player {} bought a card from the table\n\n", .{pNumber});
                }
            },
        }

        // Check if the player can claim any noble tiles
        try self.checkNobleTiles(player, pNumber);

        // Reveal players status
        std.debug.print("Player {}:\n", .{pNumber});
        player.print();
    }
};

const testing = std.testing;
test "initialize" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try Game.initialize(4, allocator);
}

test "take tokens" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize game state
    var game: Game = try Game.initialize(2, allocator);

    const player = &game.players[0];
    const tokens = [5]u8{ 1, 1, 1, 0, 0 }; // Taking 3 different tokens
    game.takeTokens(player, tokens) catch |err| {
        std.debug.print("Error taking tokens: {}\n", .{err});
    };
}

test "reserve card" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize game state
    var game: Game = try Game.initialize(2, allocator);

    const player = &game.players[0];
    const cardIndex = 0; // Index of the card to reserve
    const tier = 1; // Tier of the card to reserve
    game.reserveCard(player, cardIndex, tier) catch |err| {
        std.debug.print("Error reserving card: {}\n", .{err});
    };
}

test "purchase card" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize game state
    var game: Game = try Game.initialize(2, allocator);

    const player = &game.players[0];
    const cardIndex = 0; // Index of the card to purchase
    const tier = 1; // Tier of the card to purchase
    const fromReserve = false; // Whether the card is from reserve
    var tokens = [5]u8{ 1, 1, 1, 0, 0 };
    game.takeTokens(player, tokens) catch |err| {
        std.debug.print("Error taking tokens: {}\n", .{err});
    };
    tokens = [5]u8{ 0, 1, 1, 1, 0 };
    game.takeTokens(player, tokens) catch |err| {
        std.debug.print("Error taking tokens: {}\n", .{err});
    };
    game.purchaseCard(player, cardIndex, tier, fromReserve) catch |err| {
        std.debug.print("Error purchasing card: {}\n", .{err});
    };
}

test "check nobles" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize game state
    var game: Game = try Game.initialize(2, allocator);

    const player = &game.players[0];
    game.checkNobleTiles(player) catch |err| {
        std.debug.print("Error checking noble tiles: {}\n", .{err});
    };
}
