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
        .name = "Princess Isabel", // Mary Stuart
        .requirements = [5]u8{ 4, 0, 4, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Pedro II of Brazil", // Charles V of the Holy Roman Empire
        .requirements = [5]u8{ 0, 0, 3, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Machado de Assis",
        .requirements = [5]u8{ 0, 4, 0, 4, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Anita Garibaldi", // Isabella I of Castille
        .requirements = [5]u8{ 0, 0, 0, 4, 4 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Juscelino Kubitschek", // Suleiman the Magnificent
        .requirements = [5]u8{ 4, 4, 0, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Chiquinha Gonzaga", // Catherine of Medici
        .requirements = [5]u8{ 3, 3, 3, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Dandara dos Palmares", // Anne of Britanny
        .requirements = [5]u8{ 3, 3, 0, 3, 0 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Getúlio Vargas", // King Henry VIII of England
        .requirements = [5]u8{ 4, 0, 0, 0, 4 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Maria Quitéria", // Elisabeth of Austria, Queen of France
        .requirements = [5]u8{ 0, 3, 0, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{
        .id = undefined,
        .name = "Tiradentes", // Francis I of France
        .requirements = [5]u8{ 3, 0, 3, 0, 3 },
        .prestigePoints = 3,
    },
};
