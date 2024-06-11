pub const NobleTile = struct {
    requirements: [5]u8, // Number of each type of gem required
    prestigePoints: u8,
};

pub const nobles: []NobleTile = &[_]NobleTile{
    NobleTile{ // Mary Stuart
        .requirements = [5]u8{ 4, 0, 4, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{ // Charles V of the Holy Roman Empire
        .requirements = [5]u8{ 0, 0, 3, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{ // Niccolo Machiavelli
        .requirements = [5]u8{ 0, 4, 0, 4, 0 },
        .prestigePoints = 3,
    },
    NobleTile{ // Isabella I of Castile
        .requirements = [5]u8{ 0, 0, 0, 4, 4 },
        .prestigePoints = 3,
    },
    NobleTile{ // Suleiman the Magnificent
        .requirements = [5]u8{ 4, 4, 0, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{ // Catherine of Medici
        .requirements = [5]u8{ 3, 3, 3, 0, 0 },
        .prestigePoints = 3,
    },
    NobleTile{ // Anne of Brittany
        .requirements = [5]u8{ 3, 3, 0, 3, 0 },
        .prestigePoints = 3,
    },
    NobleTile{ // King Henry VIII of England
        .requirements = [5]u8{ 4, 0, 0, 0, 4 },
        .prestigePoints = 3,
    },
    NobleTile{ // Elisabeth of Austria, Queen of France
        .requirements = [5]u8{ 0, 3, 0, 3, 3 },
        .prestigePoints = 3,
    },
    NobleTile{ // Francis I of France
        .requirements = [5]u8{ 3, 0, 3, 0, 3 },
        .prestigePoints = 3,
    },
};
