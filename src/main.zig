const std = @import("std");

// Define custom errors
const SplendorError = error{
    InvalidMove,
    InsufficientTokens,
    InvalidTier,
    InvalidCardIndex,
};

const GemColor = enum {
    Emerald,
    Sapphire,
    Ruby,
    Diamond,
    Onyx,
    Gold,
};

const DevelopmentCard = struct {
    tier: u8,
    cost: [5]u8, // Cost in gem tokens by color
    prestigePoints: u8,
    gemBonus: ?GemColor,
};

const NobleTile = struct {
    requirements: [5]u8, // Number of each type of gem required
    prestigePoints: u8,
};

const Player = struct {
    tokens: [5]u8, // Number of each type of gem tokens
    goldTokens: u8,
    purchasedCards: std.ArrayList(DevelopmentCard),
    reservedCards: std.ArrayList(DevelopmentCard),
    prestigePoints: u8,
    nobleTiles: std.ArrayList(NobleTile),
};

const Game = struct {
    players: []Player,
    gemTokens: [5]u8, // Available gem tokens in the bank
    goldTokens: u8,
    developmentCards: []std.ArrayList(DevelopmentCard), // 3 tiers of cards
    nobleTiles: std.ArrayList(NobleTile),

    fn initialize(numPlayers: u8, allocator: std.mem.Allocator) !Game {
        // Initialize game state
        var game = Game{ .players = undefined, .gemTokens = undefined, .goldTokens = undefined, .developmentCards = undefined, .nobleTiles = undefined };
        // Initialize players
        game.players = try allocator.alloc(Player, numPlayers);
        for (game.players) |*p| {
            p.tokens = [5]u8{ 0, 0, 0, 0, 0 };
            p.goldTokens = 0;
            p.purchasedCards = std.ArrayList(DevelopmentCard).init(allocator);
            p.reservedCards = std.ArrayList(DevelopmentCard).init(allocator);
            p.prestigePoints = 0;
        }

        // Initialize gem tokens
        const tokenCount: u8 = switch (numPlayers) {
            2 => 4,
            3 => 5,
            else => 7,
        };
        game.gemTokens = [5]u8{ tokenCount, tokenCount, tokenCount, tokenCount, tokenCount };
        game.goldTokens = 5;

        // Initialize development cards
        game.developmentCards = try allocator.alloc(std.ArrayList(DevelopmentCard), 3);
        for (0..3) |t| {
            var deck = std.ArrayList(DevelopmentCard).init(allocator); // Assuming max 40 cards per tier
            // Populate deck with cards (placeholder example)
            for (0..40) |_| {
                try deck.append(DevelopmentCard{
                    .tier = @intCast(t + 1),
                    .cost = [5]u8{ 1, 1, 1, 1, 0 }, // Example cost
                    .prestigePoints = 1,
                    .gemBonus = GemColor.Emerald, // Example bonus
                });
            }
            // Shuffle deck
            var prng = std.Random.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                try std.posix.getrandom(std.mem.asBytes(&seed));
                break :blk seed;
            });
            std.Random.shuffle(prng.random(), DevelopmentCard, deck.items);
            game.developmentCards[t] = deck;
        }

        // Initialize noble tiles
        game.nobleTiles = std.ArrayList(NobleTile).init(allocator);
        for (0..(numPlayers + 1)) |_| {
            try game.nobleTiles.append(NobleTile{
                .requirements = [5]u8{ 3, 3, 3, 0, 0 }, // Example requirements
                .prestigePoints = 3,
            });
        }
        // Shuffle noble tiles
        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        std.Random.shuffle(prng.random(), NobleTile, game.nobleTiles.items[0..]);

        // Reveal initial cards for each tier
        for (0..3) |t| {
            for (0..4) |index| {
                game.developmentCards[t].items[index] = game.developmentCards[t].items[index];
            }
        }
        return game;
    }

    fn takeTokens(self: *Game, player: *Player, tokens: [5]u8) !void {
        // Logic for taking tokens
        // Count the number of tokens being taken
        var totalTokens: u8 = 0;
        for (tokens) |t| {
            totalTokens += t;
        }

        // Ensure the action is valid
        if (totalTokens > 3) {
            return error.InvalidMove; // Cannot take more than 3 tokens
        }

        var differentColors: u8 = 0;
        for (0..5) |index| {
            if (tokens[index] > 0) {
                differentColors += 1;
            }
        }

        if (differentColors > 3 or differentColors == 2) {
            return error.InvalidMove; // Cannot take more than 3 different colors
        }

        if (differentColors == 1 and totalTokens != 2) {
            return error.InvalidMove; // Must take exactly 2 tokens of the same color
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

    fn reserveCard(self: *Game, player: *Player, cardIndex: usize, tier: u8) !void {
        // Logic for reserving a card
        // Ensure the action is valid
        if (tier < 1 or tier > 3) {
            return error.InvalidTier;
        }
        if (cardIndex >= self.developmentCards[tier - 1].items.len) {
            return error.InvalidCardIndex;
        }

        // Reserve the card
        const card = self.developmentCards[tier - 1].items[cardIndex];
        try player.reservedCards.append(card);

        // Remove the card from the grid
        _ = self.developmentCards[tier - 1].orderedRemove(cardIndex);

        // Give the player a gold token if available
        if (self.goldTokens > 0) {
            self.goldTokens -= 1;
            player.goldTokens += 1;
        }
    }

    fn purchaseCard(self: *Game, player: *Player, cardIndex: usize, tier: u8, fromReserve: bool) !void {
        // Logic for purchasing a card
        // Select the card from the appropriate source
        const card: DevelopmentCard = if (fromReserve) blk: {
            if (cardIndex >= player.reservedCards.items.len) return error.InvalidCardIndex;
            break :blk player.reservedCards.items[cardIndex];
        } else blk: {
            if (tier < 1 or tier > 3) return error.InvalidTier;
            if (cardIndex >= self.developmentCards[tier - 1].items.len) return error.InvalidCardIndex;
            break :blk self.developmentCards[tier - 1].items[cardIndex];
        };

        // Calculate the cost after considering player's gem bonuses
        var remainingCost = card.cost;
        for (player.purchasedCards.items) |pCard| {
            if (pCard.gemBonus) |bonus| {
                remainingCost[@intFromEnum(bonus)] -= 1;
            }
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
            _ = player.reservedCards.orderedRemove(cardIndex);
        } else {
            _ = self.developmentCards[tier - 1].orderedRemove(cardIndex);
        }
    }

    fn checkNobleTiles(self: *Game, player: *Player) !void {
        // Check if player can claim any noble tiles
        var bonusCount = [5]u8{ 0, 0, 0, 0, 0 };

        // Count the number of each type of gem bonus from purchased cards
        for (player.purchasedCards.items) |pCard| {
            if (pCard.gemBonus) |bonus| {
                bonusCount[@intFromEnum(bonus)] += 1;
            }
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
                // Player claims the noble tile
                try player.nobleTiles.append(tile);
                player.prestigePoints += tile.prestigePoints;

                // Remove the claimed noble tile from the game
                _ = self.nobleTiles.orderedRemove(index);
            }
        }
    }

    fn isGameOver(self: *Game) bool {
        for (self.players) |p| {
            if (p.prestigePoints >= 15) {
                return true;
            }
        }
        return false;
    }

    fn printGameState(self: *Game) void {
        std.debug.print("Game State:\n", .{});
        for (self.players, 0..) |p, index| {
            std.debug.print("Player {}: {} prestige points\n", .{ index + 1, p.prestigePoints });
        }
    }

    fn playerTurn(self: *Game, player: *Player) !void {
        // Example turn sequence:
        // In a real game, you would take input from the player
        // Here, we'll simulate a simple token-taking action for demonstration
        const action = 0; // 0: Take Tokens, 1: Reserve Card, 2: Purchase Card

        switch (action) {
            0 => {
                // Simulate taking 3 different tokens
                const tokens = [5]u8{ 1, 1, 1, 0, 0 };
                try self.takeTokens(player, tokens);
            },
            1 => {
                // Simulate reserving a card from tier 1, index 0
                const cardIndex = 0;
                const tier = 1;
                try self.reserveCard(player, cardIndex, tier);
            },
            2 => {
                // Simulate purchasing a card from tier 1, index 0
                const cardIndex = 0;
                const tier = 1;
                const fromReserve = false;
                try self.purchaseCard(player, cardIndex, tier, fromReserve);
            },
            else => return error.InvalidMove,
        }

        // Check if the player can claim any noble tiles
        try self.checkNobleTiles(player);
    }
};

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize game state
    var game: Game = Game.initialize(2, allocator) catch |err| {
        std.debug.print("Can't initialize game: {}\n", .{err});
        return;
    };

    // Game loop
    while (!game.isGameOver()) {
        for (game.players) |*p| {
            // Perform player turn
            game.playerTurn(p) catch |err| {
                std.debug.print("Error during player turn: {}\n", .{err});
            };
        }

        // Print game state for debugging purposes
        game.printGameState();
    }

    // Game over
    std.debug.print("Game over!\n", .{});
    for (game.players, 0..) |p, index| {
        std.debug.print("Player {}: {} prestige points\n", .{ index + 1, p.prestigePoints });
    }
}

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
