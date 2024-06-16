const std = @import("std");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");
const am = @import("action.zig");
const gm = @import("game.zig");

const TargetCard = struct {
    card: ?cm.DevelopmentCard,
    prestige: u8,
    missingTokens: usize,
    fromReserve: bool,
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
        var affordableCard: TargetCard = TargetCard{ .card = null, .prestige = 0, .missingTokens = 999, .fromReserve = false };
        var goalCard: TargetCard = TargetCard{ .card = null, .prestige = 0, .missingTokens = 999, .fromReserve = false };
        const tooMuchTokens: usize = 5;

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
                        continue;
                    }
                }
            }

            // Check if this card is better
            if (affordable and card.prestigePoints > affordableCard.prestige) {
                affordableCard.card = card;
                affordableCard.prestige = card.prestigePoints;
                affordableCard.missingTokens = missingTokens;
                affordableCard.fromReserve = true;
            } else if (affordable and card.prestigePoints == affordableCard.prestige and missingTokens < affordableCard.missingTokens) {
                affordableCard.card = card;
                affordableCard.prestige = card.prestigePoints; // useless here, but I need to stop myself wondering why it's missing and wasting time
                affordableCard.missingTokens = missingTokens;
                affordableCard.fromReserve = true;
            }
            // Check if this card is a good goal
            if (card.prestigePoints >= goalCard.prestige and missingTokens < goalCard.missingTokens and missingTokens < tooMuchTokens) {
                goalCard.card = card;
                goalCard.prestige = card.prestigePoints;
                goalCard.missingTokens = missingTokens;
                goalCard.fromReserve = true;
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
                            continue;
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

        // if no affordable card work towards goal
        if (goalCard.card) |card| {
            // If my goal card is in danger of being bought by a player next round, reserve the best card
            for (gameState.players) |player| {
                if (player.id != self.id) {
                    var otherEffectiveCost = card.cost;
                    for (player.purchasedCards.items) |pCard| {
                        otherEffectiveCost[@intFromEnum(pCard.gemBonus)] -= @min(otherEffectiveCost[@intFromEnum(pCard.gemBonus)], 1);
                    }

                    var otherMissingTokens: usize = 0;
                    var canBuy = true;
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
                    if (canBuy and !goalCard.fromReserve and self.reservedCards.items.len < 3) {
                        return am.Action.reserveCard(card.id);
                    }
                }
            }
            // Take into account player bonuses
            var effectiveCost = card.cost;
            for (self.purchasedCards.items) |pCard| {
                effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
            }

            // Calculate missing colors
            var neededColors: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 };
            for (0..5) |colorIndex| {
                const cost = effectiveCost[colorIndex];
                if (self.tokens[colorIndex] < cost) {
                    neededColors[colorIndex] = cost -| self.tokens[colorIndex];
                }
            }

            var tokensToTake: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 };
            var sum: usize = 0;
            var nColors: usize = 0;
            var cIndex: usize = 0;
            for (neededColors, 0..) |value, colorIndex| {
                if (value >= 1) {
                    nColors += 1;
                    if (sum < 3 and gameState.gemTokens[colorIndex] > 0) {
                        tokensToTake[colorIndex] = 1;
                        sum += 1;
                        cIndex = colorIndex;
                    }
                }
            }
            if (nColors == 1 and gameState.gemTokens[cIndex] > 4) {
                tokensToTake[cIndex] += 1;
            } else {
                for (tokensToTake, 0..) |value, idx| {
                    if (sum >= 3) break;
                    if (value == 0 and gameState.gemTokens[idx] > 0) {
                        tokensToTake[idx] = 1;
                        sum += 1;
                    }
                }
            }

            tokensToTake = self.adjustTokensForLimit(tokensToTake, goalCard.card);
            sum = 0;
            for (tokensToTake) |value| {
                sum += value;
            }
            if (sum <= 1 and goalCard.card != null and !goalCard.fromReserve) return am.Action.reserveCard(card.id);
            return am.Action.takeTokens(tokensToTake);
        }

        // If no card is affordable and no card is a goal, get some tokens
        // Right now, everything down from here is really dumb but not
        // worth a lot of effort at the moment
        var neededTokens = self.calculateBestTokensToTake(gameState);
        neededTokens = self.adjustTokensForLimit(neededTokens, goalCard.card);
        return am.Action.takeTokens(neededTokens);
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

    fn calculateBestTokensToTake(self: Player, gameState: gm.Game) [5]u8 {
        var colorScores = [5]u32{ 0, 0, 0, 0, 0 };

        // Calculate the color scores based on card costs and prestige points
        for (0..3) |t| {
            for (gameState.developmentCards[t].items) |card| {
                const prestigePoints = card.prestigePoints;
                var effectiveCost = card.cost;

                for (self.purchasedCards.items) |pCard| {
                    effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
                }

                for (0..5) |colorIndex| {
                    colorScores[colorIndex] += @intCast(effectiveCost[colorIndex] * prestigePoints);
                }
            }
        }

        // Find the color with the highest score
        var bestColorIndex: usize = 0;
        var highestScore: u32 = 0;
        for (0..5) |colorIndex| {
            if (colorScores[colorIndex] > highestScore) {
                highestScore = colorScores[colorIndex];
                bestColorIndex = colorIndex;
            }
        }

        // Find the card with the lowest effective cost that has the best color
        var lowestEffectiveCost: u8 = 255;
        var targetCard: cm.DevelopmentCard = undefined;
        for (0..3) |t| {
            for (gameState.developmentCards[t].items) |card| {
                var effectiveCost = card.cost;

                for (self.purchasedCards.items) |pCard| {
                    effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
                }

                if (effectiveCost[bestColorIndex] < lowestEffectiveCost) {
                    lowestEffectiveCost = effectiveCost[bestColorIndex];
                    targetCard = card;
                }
            }
        }

        var neededTokens = [5]u8{ 0, 0, 0, 0, 0 };
        var effectiveCost = targetCard.cost;

        for (self.purchasedCards.items) |pCard| {
            effectiveCost[@intFromEnum(pCard.gemBonus)] -|= @min(effectiveCost[@intFromEnum(pCard.gemBonus)], 1);
        }

        for (0..5) |colorIndex| {
            if (self.tokens[colorIndex] < effectiveCost[colorIndex]) {
                neededTokens[colorIndex] = effectiveCost[colorIndex] - self.tokens[colorIndex];
            }
        }

        return neededTokens;
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
