const std = @import("std");
const rand = std.crypto.random;

pub const NobleTile = struct {
    id: u128,
    name: []const u8,
    requirements: [5]u8, // Number of each type of gem required
    prestigePoints: u8,
};

pub fn initialize(numPlayers: usize, allocator: std.mem.Allocator) !std.ArrayList(NobleTile) {
    var noblesCP = nobles;
    // Shuffle noble tiles
    var prng = std.Random.DefaultPrng.init(blk: {
        const seed: u64 = rand.int(u64);
        break :blk seed;
    });
    std.Random.shuffle(prng.random(), NobleTile, noblesCP[0..]);

    var ignobles = std.ArrayList(NobleTile).init(allocator);
    for (0..(numPlayers + 1)) |i| {
        var inoble = nobles[i];
        inoble.id = rand.int(u128);
        try ignobles.append(inoble);
    }
    return ignobles;
}

pub const nobles = [_]NobleTile{
    NobleTile{
        .id = undefined,
        .name = "Mary Stuart",
        .requirements = [5]u8{ 4, 0, 4, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Charles V of the Holy Roman Empire",
        .requirements = [5]u8{ 0, 0, 3, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Niccolo Machiavelli",
        .requirements = [5]u8{ 0, 4, 0, 4, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Isabella I of Castile",
        .requirements = [5]u8{ 0, 0, 0, 4, 4 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Suleiman the Magnificent",
        .requirements = [5]u8{ 4, 4, 0, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Catherine of Medici",
        .requirements = [5]u8{ 3, 3, 3, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Anne of Britanny",
        .requirements = [5]u8{ 3, 3, 0, 3, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "King Henry VIII of England",
        .requirements = [5]u8{ 4, 0, 0, 0, 4 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Elisabeth of Austria, Queen of France",
        .requirements = [5]u8{ 0, 3, 0, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Francis I of France",
        .requirements = [5]u8{ 3, 0, 3, 0, 3 },
        .prestigePoints = 3,
    },
};
