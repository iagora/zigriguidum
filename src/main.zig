const std = @import("std");
const gm = @import("game.zig");
const pm = @import("player.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var players = [_]pm.Player{ pm.Player.create(allocator), pm.Player.create(allocator), pm.Player.create(allocator), pm.Player.create(allocator) };
    // var players = [_]pm.Player{ pm.Player.create(allocator), pm.Player.create(allocator) };

    // Initialize game state
    var game: gm.Game = gm.Game.initialize(&players, allocator) catch |err| {
        std.debug.print("Can't initialize game: {}\n", .{err});
        return;
    };

    // gm.Game loop
    gblk: while (!game.isGameOver()) {
        // Print game state for debugging purposes
        var gameState = try game.generateGameState(allocator);
        gameState.print();

        // Give each player a turn
        for (game.players, 1..) |*p, pn| {
            // Generate the game state to present to player;
            gameState = try game.generateGameState(allocator);

            // This is where I can serialize the game state to a json send it to anyone.
            // Player receives the game state, outputs an action that could potentially be
            // serialized, game receives the action and tries to apply it
            const action = p.play(gameState);

            // Perform player turn
            game.turn(action, p) catch |err| {
                std.debug.print("Error during player {}'s turn:\nAction: {any}\nError:{}\n", .{ pn, action, err });
            };
        }
        if (game.round >= 100) {
            std.debug.print("Game running for too long without a winner!\n", .{});
            break :gblk;
        }
    }

    // gm.Game over
    std.debug.print("Game over!\n", .{});
    for (game.players, 0..) |p, index| {
        std.debug.print("Player {}: {} prestige points\n", .{ index + 1, p.prestigePoints });
    }
}
