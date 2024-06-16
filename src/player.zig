const std = @import("std");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");
const am = @import("action.zig");
const gm = @import("game.zig");

const TargetCard = struct {
    card: ?cm.DevelopmentCard,
    index: usize,
    isReserve: bool,
    missingTokens: usize,
};

pub const Player = struct {
    id: u256,
    tokens: [5]u8, // Number of each type of gem tokens
    goldTokens: u8,
    purchasedCards: std.ArrayList(cm.DevelopmentCard),
    reservedCards: std.ArrayList(cm.DevelopmentCard),
    prestigePoints: u8,
    nobleTiles: std.ArrayList(nm.NobleTile),

    pub fn create(allocator: std.mem.Allocator) Player {
        const rand = std.crypto.random;
        const player = Player{
            .id = rand.int(u256),
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
        var bestCard: TargetCard = TargetCard{ .card = null, .index = undefined, .isReserve = undefined, .missingTokens = 999 };
        var goalCard: TargetCard = TargetCard{ .card = null, .index = undefined, .isReserve = undefined, .missingTokens = 999 };
        const tooMuchTokens: usize = 8;

        // Find the best card to aim for
        for (self.reservedCards.items, 0..) |card, index| {
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
            const highestPrestige = if (bestCard.card) |bcard| bcard.prestigePoints else 0;
            if (affordable and card.prestigePoints > highestPrestige) {
                bestCard.card = card;
                bestCard.index = index;
                bestCard.isReserve = true;
                bestCard.missingTokens = missingTokens;
            } else if (affordable and card.prestigePoints == highestPrestige and missingTokens < bestCard.missingTokens) {
                bestCard.card = card;
                bestCard.index = index;
                bestCard.isReserve = true;
                bestCard.missingTokens = missingTokens;
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
                const highestPrestige = if (bestCard.card) |bcard| bcard.prestigePoints else 0;
                if (affordable and card.prestigePoints > highestPrestige) {
                    bestCard.card = card;
                    bestCard.index = index;
                    bestCard.missingTokens = missingTokens;
                } else if (affordable and card.prestigePoints == highestPrestige and missingTokens < bestCard.missingTokens) {
                    bestCard.card = card;
                    bestCard.index = index;
                    bestCard.missingTokens = missingTokens;
                }
                // Check if this card is a good goal
                const highestGoalPrestige = if (goalCard.card) |gcard| gcard.prestigePoints else 0;
                if (card.prestigePoints >= highestGoalPrestige and missingTokens < tooMuchTokens) {
                    goalCard.card = card;
                    goalCard.index = index;
                    goalCard.missingTokens = missingTokens;
                }
            }
        }

        // If a card is affordable, buy it
        if (bestCard.card) |card| {
            // Calculate missing tokens
            var effectiveCost = card.cost;
            for (self.purchasedCards.items) |pCard| {
                effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
            }

            // If we can afford the card with gold tokens
            if (bestCard.missingTokens <= self.goldTokens) {
                if (bestCard.isReserve) return am.Action.purchaseCard(bestCard.index, card.tier, true);
                return am.Action.purchaseCard(bestCard.index, card.tier, false);
            }
        }

        // If no card is affordable, reserve the best card
        if (goalCard.card) |card| {
            for (gameState.players) |player| {
                if (player.id != self.id) {
                    var otherEffectiveCost = card.cost;
                    for (player.purchasedCards.items) |pCard| {
                        otherEffectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(otherEffectiveCost[@intFromEnum(pCard.gemBonus)], 1);
                    }

                    var otherMissingTokens: usize = 0;
                    var canBuy: bool = true;
                    for (0..5) |colorIndex| {
                        const cost = otherEffectiveCost[colorIndex];
                        const availableTokens = player.tokens[colorIndex] + player.goldTokens;
                        if (availableTokens < cost) {
                            otherMissingTokens += cost - availableTokens;
                            if (otherMissingTokens > player.goldTokens) {
                                canBuy = false;
                                break;
                            }
                        }
                    }

                    // If another player can buy the card in their next turn, reserve it
                    if (canBuy and self.reservedCards.items.len < 3) {
                        return am.Action.reserveCard(goalCard.index, card.tier);
                    }
                }
            }

            // Calculate missing tokens
            var effectiveCost = card.cost;
            for (self.purchasedCards.items) |pCard| {
                effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
            }

            // Calculate what are we lacking to purchase the card
            var neededColors = [5]u8{ 0, 0, 0, 0, 0 };
            for (0..5) |colorIndex| {
                const cost = effectiveCost[colorIndex];
                if (self.tokens[colorIndex] < cost) {
                    neededColors[colorIndex] = cost -| self.tokens[colorIndex];
                }
            }
            var totalNeeded: u8 = 0;
            for (neededColors) |value| {
                totalNeeded += value;
            }
            var tokensToTake = [5]u8{ 0, 0, 0, 0, 0 };
            var tokensTaken: u8 = 0;
            for (neededColors, 0..5) |amountNeeded, colorIndex| {
                if (totalNeeded == 2 and amountNeeded == 2 and gameState.gemTokens[colorIndex] >= 4) {
                    tokensToTake[colorIndex] = 2;
                    tokensTaken += 2;
                    tokensToTake = self.adjustTokensForLimit(tokensToTake, goalCard.card);
                    var sum: u8 = 0;
                    for (tokensToTake) |value| {
                        sum += value;
                    }
                    if (sum <= 1 and goalCard.card != null) return am.Action.reserveCard(goalCard.index, card.tier);
                    return am.Action.takeTokens(tokensToTake);
                }
                if (amountNeeded > 0 and gameState.gemTokens[colorIndex] > 0 and tokensTaken < 3) {
                    tokensToTake[colorIndex] = 1;
                    tokensTaken += 1;
                }
            }

            for (0..5) |colorIndex| {
                if (tokensTaken < 3 and tokensToTake[colorIndex] == 0 and gameState.gemTokens[colorIndex] > 0) {
                    tokensToTake[colorIndex] += 1;
                    tokensTaken += 1;
                }
            }
            tokensToTake = self.adjustTokensForLimit(tokensToTake, goalCard.card);
            var sum: u8 = 0;
            for (tokensToTake) |value| {
                sum += value;
            }
            if (sum <= 1 and goalCard.card != null) return am.Action.reserveCard(goalCard.index, card.tier);
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

        tokensToTake = self.adjustTokensForLimit(tokensToTake, bestCard.card);
        var sum: u8 = 0;
        for (tokensToTake) |value| {
            sum += value;
        }
        if (sum <= 1) if (bestCard.card) |card| return am.Action.reserveCard(bestCard.index, card.tier);
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

        if (targetCard) |bestCard| {
            // Determine needed tokens for best card
            var neededTokens = [5]u8{ 0, 0, 0, 0, 0 };
            var effectiveCost = bestCard.cost;
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
