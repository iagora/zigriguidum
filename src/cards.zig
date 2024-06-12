const std = @import("std");

pub const GemColor = enum {
    Emerald,
    Sapphire,
    Ruby,
    Diamond,
    Onyx,
};

pub const DevelopmentCard = struct {
    tier: u8,
    cost: [5]u8, // Cost in gem tokens by color
    prestigePoints: u8,
    gemBonus: GemColor,

    pub fn print(self: DevelopmentCard) void {
        const color = switch (self.gemBonus) {
            GemColor.Emerald => "emerald",
            GemColor.Sapphire => "sapphire",
            GemColor.Ruby => "ruby",
            GemColor.Diamond => "diamond",
            GemColor.Onyx => "onyx",
        };
        std.debug.print("cost: {any}\tprestige: {}\tcolor: {s} {{{any}}}\n", .{ self.cost, self.prestigePoints, color, @intFromEnum(self.gemBonus) + 1 });
    }
};

pub fn initialize(allocator: std.mem.Allocator) ![]std.ArrayList(DevelopmentCard) {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const devCards = try allocator.alloc(std.ArrayList(DevelopmentCard), 3);
    var deck = std.ArrayList(DevelopmentCard).init(allocator);
    for (deck1) |card| {
        try deck.append(card);
        std.Random.shuffle(prng.random(), DevelopmentCard, deck.items);
        devCards[0] = deck;
    }
    deck = std.ArrayList(DevelopmentCard).init(allocator);
    for (deck2) |card| {
        try deck.append(card);
        std.Random.shuffle(prng.random(), DevelopmentCard, deck.items);
        devCards[1] = deck;
    }
    deck = std.ArrayList(DevelopmentCard).init(allocator);
    for (deck3) |card| {
        try deck.append(card);
        std.Random.shuffle(prng.random(), DevelopmentCard, deck.items);
        devCards[2] = deck;
    }
    return devCards;
}

pub const deck1 = [_]DevelopmentCard{
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 1, 1, 1, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 2, 1, 1, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 2, 1, 2, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 0, 3, 0, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 2, 0, 1, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 2, 0, 0, 2, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 3, 0, 0, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 4, 0, 0, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 0, 1, 1, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 0, 2, 1, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 2, 0, 2, 1, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 3, 1, 1, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 0, 1, 2 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 2, 0, 0, 0, 2 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 0, 0, 3 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 4, 0, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 1, 1, 0, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 2, 1, 1, 0, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 2, 2, 0, 0, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 1, 0, 3, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 2, 0, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 2, 0, 0, 2 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 3, 0, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 4, 0, 0, 0, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 1, 1, 1, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 1, 1, 1, 2 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 1, 2, 0, 2 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 3, 0, 1, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 1, 0, 2, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 2, 2, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 3, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 0, 0, 4 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 1, 0, 1, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 1, 0, 2, 1 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 0, 0, 2, 2 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 1, 1, 3 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 1, 2, 0, 0, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 2, 2, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 0, 3, 0 },
        .prestigePoints = 0,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 1,
        .cost = [5]u8{ 0, 0, 0, 4, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Ruby,
    },
};

pub const deck2 = [_]DevelopmentCard{
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 2, 2, 0, 3, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 3, 0, 0, 3, 2 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 4, 1, 2, 0, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 5, 0, 3, 0, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 0, 5, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 0, 0, 6 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 2, 2, 3, 0, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 3, 2, 0, 0, 3 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 3, 0, 5, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 1, 2, 4 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 5, 0, 0, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 6, 0, 0, 0 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 3, 0, 2, 0, 2 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 3, 3, 2, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 1, 0, 4, 0, 2 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 5, 0, 3 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 5, 0, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 0, 6, 0 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 2, 0, 3, 3, 0 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 3, 0, 2, 2 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 2, 0, 4, 1 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 3, 5, 0, 0, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 5, 0, 0, 0, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 6, 0, 0, 0, 0 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 2, 2, 3 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 3, 2, 0, 3 },
        .prestigePoints = 1,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 2, 4, 0, 1, 0 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 0, 3, 5 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 0, 0, 5 },
        .prestigePoints = 2,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 2,
        .cost = [5]u8{ 0, 0, 6, 0, 0 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Ruby,
    },
};

pub const deck3 = [_]DevelopmentCard{
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 5, 3, 3, 3, 0 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 0, 7, 0, 0 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 3, 0, 6, 0, 3 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 0, 7, 0, 3 },
        .prestigePoints = 5,
        .gemBonus = GemColor.Onyx,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 3, 0, 3, 3, 5 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 0, 0, 7, 0 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 3, 0, 6, 3 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 3, 0, 7, 0 },
        .prestigePoints = 5,
        .gemBonus = GemColor.Sapphire,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 3, 3, 5, 0, 3 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 0, 0, 0, 7 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 0, 3, 3, 6 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 0, 0, 3, 7 },
        .prestigePoints = 5,
        .gemBonus = GemColor.Diamond,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 3, 3, 5, 3 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 0, 7, 0, 0, 0 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 3, 6, 0, 3, 0 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 3, 7, 0, 0, 0 },
        .prestigePoints = 5,
        .gemBonus = GemColor.Emerald,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 3, 5, 0, 3, 3 },
        .prestigePoints = 3,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 7, 0, 0, 0, 0 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 6, 3, 3, 0, 0 },
        .prestigePoints = 4,
        .gemBonus = GemColor.Ruby,
    },
    DevelopmentCard{
        .tier = 3,
        .cost = [5]u8{ 7, 0, 3, 0, 0 },
        .prestigePoints = 5,
        .gemBonus = GemColor.Ruby,
    },
};
