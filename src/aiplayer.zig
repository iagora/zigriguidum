// xaelleone's AI ported to Zig under MIT license

const std = @import("std");
const pm = @import("player.zig");
const cm = @import("cards.zig");
const nm = @import("nobles.zig");
const gm = @import("game.zig");

const Colorset = struct {
    dict_of_colors: [5]u8,

    pub fn max(self: Colorset) u8 {
        var tmp: u8 = self.dict_of_colors[0];
        for (self.dict_of_colors) |value| {
            if (value > tmp) {
                tmp = value;
            }
        }
        return tmp;
    }

    pub fn subtract_to_zero(self: Colorset, other: Colorset) Colorset {
        var result = Colorset{ .dict_of_colors = [5]u8{} };
        for (0..5) |index| {
            result.dict_of_colors[index] = if (self.dict_of_colors[index] > other.dict_of_colors[index]) self.dict_of_colors[index] - other.dict_of_colors[index] else 0;
        }
        return result;
    }

    pub fn combine(self: Colorset, other: Colorset) Colorset {
        var result = Colorset{ .dict_of_colors = [5]u8{} };
        for (0..5) |index| {
            result.dict_of_colors[index] = self.dict_of_colors[index] + other.dict_of_colors[index];
        }
        return result;
    }

    pub fn total(self: Colorset) u8 {
        var ret: u8 = 0;
        for (0..5) |index| {
            ret += self.dict_of_colors[index];
        }
        return ret;
    }
};

const AIPlayer = struct {
    player: pm.Player,
    turn_counter: u8,
    care_about_this: []cm.DevelopmentCard,
    goal_card: cm.DevelopmentCard,
    turns_to_care_per_tier: [3][2]u8,
    max_cost_per_tier: [3]u8,
    max_to_pay: u8,
    too_far: u8,

    pub fn create(allocator: *std.mem.Allocator) !AIPlayer {
        return AIPlayer{
            .player = pm.Player.create(true, allocator),
            .turn_counter = 1,
            .care_about_this = try allocator.alloc(cm.DevelopmentCard, 0),
            .goal_card = cm.DevelopmentCard{
                .tier = 0,
                .cost = [5]u8{},
                .prestigePoints = 0,
                .gemBonus = null,
            },
            .turns_to_care_per_tier = [_][2]u8{
                [2]u8{ 0, 10 },
                [2]u8{ 6, 15 },
                [2]u8{ 8, 100 },
            },
            .max_cost_per_tier = [3]u8{ 4, 7, 13 },
            .max_to_pay = 3,
            .too_far = 3,
        };
    }

    pub fn takeTurn(self: *AIPlayer, game_state: *gm.Game, allocator: *std.mem.Allocator) !void {
        self.turn_counter += 1;

        const tt = struct {
            fn scanGoodCards(ai: *AIPlayer, tier: u8, gs: *gm.Game) !void {
                if (ai.turn_counter > ai.turns_to_care_per_tier[tier][0] and ai.turn_counter < ai.turns_to_care_per_tier[tier][1]) {
                    for (gs.developmentCards[tier].items) |*card| {
                        if (card.cost.total() <= ai.max_cost_per_tier[tier]) {
                            ai.care_about_this = try allocator.append(ai.care_about_this, card);
                        }
                    }
                }
            }
        }.tt;

        try tt.scanGoodCards(self, 0, game_state);
        try tt.scanGoodCards(self, 1, game_state);
        try tt.scanGoodCards(self, 2, game_state);

        if (self.care_about_this.len == 0) {
            // Take tokens action
            const tokens = Colorset{ .dict_of_colors = [5]u8{ 1, 1, 1, 0, 0 } };
            try gm.Game.takeTokens(&self.player, game_state, tokens.dict_of_colors);
            return;
        }

        // Determine goal card
        const current_best_point = 0;
        self.goal_card = self.care_about_this[0];
        for (self.care_about_this) |*card| {
            if (!game_state.developmentCards[0].contains(card) and !game_state.developmentCards[1].contains(card) and !game_state.developmentCards[2].contains(card)) {
                self.care_about_this = try allocator.remove(self.care_about_this, card);
            }
            if (card.prestigePoints > current_best_point and card.tier != 0) {
                self.goal_card = card;
            }
        }

        std.debug.print("This is turn {}\n", .{self.turn_counter});
        std.debug.print("I care about {}\n", .{self.care_about_this});
        std.debug.print("My goal is currently {}\n", .{self.goal_card.cost});

        // Obtain goal card if possible
        const goal_colors = self.goal_card.cost;
        const board_colorset = Colorset{ .dict_of_colors = [5]u8{} }; // Implement logic to get tableau colorset
        var needed_colors = goal_colors.subtract_to_zero(board_colorset);
        needed_colors = needed_colors.subtract_to_zero(Colorset{ .dict_of_colors = self.player.tokens });

        if (needed_colors.total() <= self.player.goldTokens) {
            try gm.Game.purchaseCard(&self.player, game_state, 0, self.goal_card.tier, false, allocator); // Find actual index
            return;
        }

        // Purchase cards that help goal from better cards if possible
        for (self.care_about_this) |*card| {
            if (needed_colors.dict_of_colors[card.gemBonus.?] != 0 and gm.Game.canBuy(&self.player, card)) {
                try gm.Game.purchaseCard(&self.player, game_state, 0, card.tier, false, allocator); // Find actual index
                return;
            }
        }

        // Purchase cards in general that help goal
        for (game_state.developmentCards[0]) |*card| {
            if (needed_colors.dict_of_colors[card.gemBonus.?] != 0 and gm.Game.canBuy(&self.player, card)) {
                try gm.Game.purchaseCard(&self.player, game_state, 0, card.tier, false, allocator); // Find actual index
                return;
            }
        }

        // Purchase cards that might help in general
        for (0..3) |t| {
            for (game_state.developmentCards[t]) |*card| {
                const effective_cost = card.cost.subtract_to_zero(board_colorset).total();
                if (effective_cost < self.max_to_pay and gm.Game.canBuy(&self.player, card) and needed_colors.dict_of_colors[card.gemBonus.?] != 0) {
                    try gm.Game.purchaseCard(&self.player, game_state, 0, card.tier, false, allocator); // Find actual index
                    return;
                }
            }
        }

        // Reserve cards if you need too many of a color
        if (needed_colors.max() > self.too_far and self.player.reservedCards.len < 3) {
            var most_achievable = self.care_about_this[0];
            for (self.care_about_this) |*card| {
                const effective_cost = card.cost.subtract_to_zero(board_colorset).total();
                if (effective_cost < most_achievable.cost.total()) {
                    most_achievable = card;
                }
            }
            try gm.Game.reserveCard(&self.player, game_state, 0, most_achievable.tier, allocator); // Find actual index
            return;
        }

        // Take chips if all else fails
        var taking_these = Colorset{ .dict_of_colors = [5]u8{} };
        for (0..5) |i| {
            if (taking_these.total() < 3) {
                taking_these = taking_these.combine(Colorset{ .dict_of_colors = [5]u8{} });
                taking_these.dict_of_colors[i] = 1;
            }
        }

        try gm.Game.takeTokens(&self.player, game_state, taking_these.dict_of_colors);
    }
};
