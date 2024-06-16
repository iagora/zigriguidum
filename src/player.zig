const std = @import("std");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");
const am = @import("action.zig");
const gm = @import("game.zig");

const TargetCard = struct {
    card: ?cm.DevelopmentCard,
    prestige: u8,
    missingTokens: usize,
};

pub const Player = struct {
    id: u128,
    tokens: [5]u8, // Number of each type of gem tokens
    goldTokens: u8,
    purchasedCards: std.ArrayList(cm.DevelopmentCard),
    reservedCards: std.ArrayList(cm.DevelopmentCard),
    prestigePoints: u8,
    nobleTiles: std.ArrayList(nm.NobleTile),

    pub fn create(allocator: std.mem.Allocator) Player {
        const rand = std.crypto.random;
        const player = Player{
            .id = rand.int(u128),
            .tokens = [5]u8{ 0, 0, 0, 0, 0 },
            .goldTokens = 0,
            .purchasedCards = std.ArrayList(cm.DevelopmentCard).init(allocator),
            .reservedCards = std.ArrayList(cm.DevelopmentCard).init(allocator),
            .prestigePoints = 0,
            .nobleTiles = std.ArrayList(nm.NobleTile).init(allocator),
        };
        return player;
    }

    pub fn play(self: Player, gameState: gm.Game) am.Action {
        var affordableCard: TargetCard = TargetCard{ .card = null, .prestige = 0, .missingTokens = 999 };
        var goalCard: TargetCard = TargetCard{ .card = null, .prestige = 0, .missingTokens = 999 };
        const tooMuchTokens: usize = 6;

        // Find the best card to aim for
        for (self.reservedCards.items) |card| {
            var missingTokens: usize = 0;
            var affordable = true;

            // Calculate missing tokens
            var effectiveCost = card.cost;
            for (self.purchasedCards.items) |pCard| {
                effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
            }

            for (0..5) |colorIndex| {
                const cost = effectiveCost[colorIndex];
                const availableTokens = self.tokens[colorIndex];
                if (availableTokens < cost) {
                    missingTokens += cost - availableTokens;
                    if (missingTokens > self.goldTokens) {
                        affordable = false;
                        break;
                    }
                }
            }

            // Check if this card is better
            if (affordable and card.prestigePoints > affordableCard.prestige) {
                affordableCard.card = card;
                affordableCard.prestige = card.prestigePoints;
                affordableCard.missingTokens = missingTokens;
            } else if (affordable and card.prestigePoints == affordableCard.prestige and missingTokens < affordableCard.missingTokens) {
                affordableCard.card = card;
                affordableCard.prestige = card.prestigePoints; // useless here, but I need to stop myself wondering why it's missing and wasting time
                affordableCard.missingTokens = missingTokens;
            }
            // Check if this card is a good goal
            if (card.prestigePoints >= goalCard.prestige and missingTokens < goalCard.missingTokens and missingTokens < tooMuchTokens) {
                goalCard.card = card;
                goalCard.prestige = card.prestigePoints;
                goalCard.missingTokens = missingTokens;
            }
        }
        for (0..3) |t| {
            for (0..gameState.developmentCards[2 - t].items.len) |index| {
                const card = gameState.developmentCards[2 - t].items[index];
                var missingTokens: usize = 0;
                var affordable = true;

                // Calculate missing tokens
                var effectiveCost = card.cost;
                for (self.purchasedCards.items) |pCard| {
                    effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
                }

                for (0..5) |colorIndex| {
                    const cost = effectiveCost[colorIndex];
                    const availableTokens = self.tokens[colorIndex];
                    if (availableTokens < cost) {
                        missingTokens += cost - availableTokens;
                        if (missingTokens > self.goldTokens) {
                            affordable = false;
                            break;
                        }
                    }
                }

                // Check if this card is better
                if (affordable and card.prestigePoints > affordableCard.prestige) {
                    affordableCard.card = card;
                    affordableCard.prestige = card.prestigePoints;
                    affordableCard.missingTokens = missingTokens;
                } else if (affordable and card.prestigePoints == affordableCard.prestige and missingTokens < affordableCard.missingTokens) {
                    affordableCard.card = card;
                    affordableCard.prestige = card.prestigePoints; // useless here, but I need to stop myself wondering why it's missing and wasting time
                    affordableCard.missingTokens = missingTokens;
                }
                // Check if this card is a good goal
                if (card.prestigePoints >= goalCard.prestige and missingTokens < goalCard.missingTokens and missingTokens < tooMuchTokens) {
                    goalCard.card = card;
                    goalCard.prestige = card.prestigePoints;
                    goalCard.missingTokens = missingTokens;
                }
            }
        }

        // TODO: add logic to decide weather to aim for affordable or goal

        // If a card is affordable, buy it
        if (affordableCard.card) |card| {
            // Calculate missing tokens
            var effectiveCost = card.cost;
            for (self.purchasedCards.items) |pCard| {
                effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
            }

            // Calculate if we can buy the card
            var neededColors = [5]u8{ 0, 0, 0, 0, 0 };
            for (0..5) |colorIndex| {
                const cost = effectiveCost[colorIndex];
                if (self.tokens[colorIndex] < cost) {
                    neededColors[colorIndex] = cost -| self.tokens[colorIndex];
                }
            }
            // If we can afford the card with gold tokens
            if (affordableCard.missingTokens <= self.goldTokens) {
                return am.Action.purchaseCard(card.id);
            }
        }

        // If no card is affordable, reserve the best card
        if (goalCard.card) |card| {
            var tokensToTake = [5]u8{ 0, 0, 0, 0, 0 };
            var tokensTaken: u8 = 0;
            for (0..5) |colorIndex| {
                if (gameState.gemTokens[colorIndex] > 0 and tokensTaken < 3) {
                    tokensToTake[colorIndex] = 1;
                    tokensTaken += 1;
                }
            }
            tokensToTake = self.adjustTokensForLimit(tokensToTake, goalCard.card);
            if (std.mem.eql(u8, &tokensToTake, &[5]u8{ 0, 0, 0, 0, 0 }) and goalCard.card != null) return am.Action.reserveCard(card.id);
            return am.Action.takeTokens(tokensToTake);
        }

        // If no card is affordable, take tokens
        var tokensToTake = [5]u8{ 0, 0, 0, 0, 0 };
        var tokensTaken: u8 = 0;
        for (0..5) |colorIndex| {
            if (gameState.gemTokens[colorIndex] > 0 and tokensTaken < 3) {
                tokensToTake[colorIndex] = 1;
                tokensTaken += 1;
            }
        }

        tokensToTake = self.adjustTokensForLimit(tokensToTake, goalCard.card);
        var sum: usize = 0;
        for (tokensToTake) |value| {
            sum += value;
        }
        if (sum <= 1) if (goalCard.card) |card| return am.Action.reserveCard(card.id);
        return am.Action.takeTokens(tokensToTake);
    }

    fn adjustTokensForLimit(self: Player, tokens: [5]u8, targetCard: ?cm.DevelopmentCard) [5]u8 {
        var currentTotal: u8 = 0;
        for (self.tokens) |t| {
            currentTotal += t;
        }

        var totalRequested: u8 = 0;
        for (tokens) |t| {
            totalRequested += t;
        }

        if (currentTotal + totalRequested <= 10) {
            return tokens;
        }

        if (targetCard) |tCard| {
            // Determine needed tokens for best card
            var neededTokens = [5]u8{ 0, 0, 0, 0, 0 };
            var effectiveCost = tCard.cost;
            for (self.purchasedCards.items) |pCard| {
                effectiveCost[@intFromEnum(pCard.gemBonus)] -= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
            }

            for (0..5) |colorIndex| {
                const cost = effectiveCost[colorIndex];
                if (self.tokens[colorIndex] < cost) {
                    neededTokens[colorIndex] = cost - self.tokens[colorIndex];
                }
            }

            // Adjust tokens to not exceed the limit
            var adjustedTokens = [5]u8{ 0, 0, 0, 0, 0 };
            var tokensTaken: u8 = 0;
            for (0..5) |colorIndex| {
                if (tokens[colorIndex] > 0 and tokensTaken < (10 - currentTotal)) {
                    // Prioritize keeping needed tokens
                    if (neededTokens[colorIndex] > 0) {
                        adjustedTokens[colorIndex] = tokens[colorIndex];
                        tokensTaken += tokens[colorIndex];
                    } else if (tokensTaken + tokens[colorIndex] <= (10 - currentTotal)) {
                        adjustedTokens[colorIndex] = tokens[colorIndex];
                        tokensTaken += tokens[colorIndex];
                    } else {
                        adjustedTokens[colorIndex] = 10 - currentTotal - tokensTaken;
                        tokensTaken = 10 - currentTotal;
                    }
                }
            }

            return adjustedTokens;
        } else {
            var tokensToTake = [5]u8{ 0, 0, 0, 0, 0 };
            var tokensTaken: u8 = 0;
            for (0..5) |colorIndex| {
                if (tokens[colorIndex] > 0 and tokensTaken < (10 - currentTotal)) {
                    tokensToTake[colorIndex] = 1;
                    tokensTaken += 1;
                }
            }

            return tokensToTake;
        }
    }

    pub fn print(self: Player) void {
        std.debug.print("prestige: {}\ttokens: {any}\tgold: {}\n", .{ self.prestigePoints, self.tokens, self.goldTokens });
        var bonus = [5]u8{ 0, 0, 0, 0, 0 };
        for (self.purchasedCards.items) |pCard| {
            bonus[@intFromEnum(pCard.gemBonus)] += 1;
        }
        std.debug.print("bonus:\t{any}\n", .{bonus});
        std.debug.print("visiting nobles:\n", .{});
        for (self.nobleTiles.items) |noble| {
            std.debug.print("{s} -> {any}\n", .{ noble.name, noble.requirements });
        }
        std.debug.print("owned cards:\n", .{});
        for (self.purchasedCards.items) |card| {
            card.print();
        }
        std.debug.print("reserved cards:\n", .{});
        for (self.reservedCards.items) |card| {
            card.print();
        }

        std.debug.print("\n", .{});
    }
};
