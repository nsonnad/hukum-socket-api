# HukumSockets

## Master TODO across all 3 repos:


- [\] figure out how to display errors like `username taken` or `game doesn't
      exist`
      -> figured out how but have not actually implemented it
- [ ] need mechanism for allowing interaction only when it's a given player's
      turn
- [ ] UI for call/pass, and which trump to call etc
- [ ] Elm needs to send all possible player actions

## Done:
- [x] are the players sorted correctly? probably not
      -> i think so! (maybe...)
- [x] phoenix needs to handle all possible player actions
      -> done i think?
- [x] leaving a room/topic/channel should remove a player from a game (so we need
      `HukumEngine.remove_player`)
      -> maybe we can just use `presence_diff` to do this, or otherwise use
      presence
- [x] HukumEngine: on new hand, assign random dealer from losing team
- [x] UI for choosing teams
- [x] starting a new game
- [x] joining an existing (private?) game using its unique name
- [x] joining one of the open games listed
