const std = @import("std");
const gm = @import("game.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize game state
    var game: gm.Game = gm.Game.initialize(2, allocator) catch |err| {
        std.debug.print("Can't initialize game: {}\n", .{err});
        return;
    };

    // gm.Game loop
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

    // gm.Game over
    std.debug.print("Game over!\n", .{});
    for (game.players, 0..) |p, index| {
        std.debug.print("Player {}: {} prestige points\n", .{ index + 1, p.prestigePoints });
    }
}
