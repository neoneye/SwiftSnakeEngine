# SwiftSnakeEngine - Dataset

When a snake game ends, most of its game data is stored in a `.snakeDataset` file.

This `.snakeDataset` file, can be used for these things:

- Create a video, with one player move per frame.
- Replay of a historical game, for later inspection of the game state.
- Train data for a neural network.
- Verify that no cheating was going on.

---

# Content of the dataset file

Recreating a historical game, requires these kinds of data:

- Level.
- Food positions.
- Info about player 1 and player 2.
- When did the game take place.
- How long did the game take.

Info about each player:

- List of all the moves made by the player.
- Is the player a bot. If so, what is the `uuid` of the bot.
- Is the player a human. If so, how many undo operations did the human make.
- Is the player not installed. In a two-player game, both players are installed. In a single-player game, one of the players is installed.
- Why did the player die?  Collision with wall, Collision with snake, Stuck in a loop.


### Level

In what level did the game take place.

The level can have been renamed, so simply refering to its filename, is fragile.
In order to reference the level, I make use the level `uuid`.

The content of the level can be changed. So I store basic level info.
So even though the level have been modified, the game can still be replayed.

