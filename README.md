# HukumSockets

## Master TODO across all 3 repos:

- [ ] leaving a room/topic/channel should remove a player from a game (so we need
      `HukumEngine.remove_player`)
      -> maybe we can just use `presence_diff` to do this, or otherwise use
      presence

- [ ] figure out how to display errors like `username taken` or `game doesn't
      exist`
- [ ] UI for choosing teams
- [ ] phoenix needs to handle all possible player actions
- [ ] Elm needs to send all possible player actions
- [ ] are the players sorted correctly? probably not
- [ ] design the actual game part

Joining rooms:
- [x] starting a new game
- [x] joining an existing (private?) game using its unique name
- [x] joining one of the open games listed
