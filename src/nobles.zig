const std = @import("std");

pub const NobleTile = struct {
    name: []const u8,
    requirements: [5]u8, // Number of each type of gem required
    prestigePoints: u8,
};

pub fn initialize(numPlayers: u8, allocator: std.mem.Allocator) !std.ArrayList(NobleTile) {
    var noblesCP = nobles;
    // Shuffle noble tiles
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    std.Random.shuffle(prng.random(), NobleTile, noblesCP[0..]);

    var ignobles = std.ArrayList(NobleTile).init(allocator);
    for (0..(numPlayers + 1)) |i| {
        try ignobles.append(nobles[i]);
    }
    return ignobles;
}

pub const nobles = [_]NobleTile{
    NobleTile{
        .name = "Mary Stuart",
        .requirements = [5]u8{ 4, 0, 4, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Charles V of the Holy Roman Empire",
        .requirements = [5]u8{ 0, 0, 3, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Niccolo Machiavelli",
        .requirements = [5]u8{ 0, 4, 0, 4, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Isabella I of Castile",
        .requirements = [5]u8{ 0, 0, 0, 4, 4 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Suleiman the Magnificent",
        .requirements = [5]u8{ 4, 4, 0, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Catherine of Medici",
        .requirements = [5]u8{ 3, 3, 3, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Anne of Britanny",
        .requirements = [5]u8{ 3, 3, 0, 3, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "King Henry VIII of England",
        .requirements = [5]u8{ 4, 0, 0, 0, 4 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Elisabeth of Austria, Queen of France",
        .requirements = [5]u8{ 0, 3, 0, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{
        .name = "Francis I of France",
        .requirements = [5]u8{ 3, 0, 3, 0, 3 },
        .prestigePoints = 3,
    },
};
