# Classic Endgame Reference Candidates

These files are downloaded reference candidates for the planned four-classic-endgame challenge. They are not training data and must not be imported into `+alphazero` until every board position, starting side, and target result has been independently verified.

## Downloaded Sources

- `candidate_endgames_ZDSxbj_ChineseChess.ts`
  - Repository: `ZDSxbj/ChineseChess`
  - Commit: `9b7dd854a3e58c0b4445d3ad7a58fab068d65cff`
  - Source path: `frontend/src/data/endgameData.ts`
  - Contains candidate positions named `七星聚会`, `蚯蚓降龙`, and `野马操田`.

- `candidate_endgames_zhangvoice_games.json`
  - Repository: `zhangvoice/games`
  - Commit: `a9a52f5bd839f1c814f07ab050d6ac9fa5439241`
  - Source path: `games/chinese_chess/endgames.json`
  - Contains simplified positions named `七星聚会(简)` and `野马操田(局)`.

## Verification Status

The sources disagree in scope and presentation. The first source includes positions whose material does not fully match the intended descriptions, and the second explicitly labels its positions as simplified. Neither source provides a candidate position named `千里独行`.

Do not treat names alone as an authoritative identification of a classic endgame. The project requires one verified source record per challenge containing the board coordinates, initial side to move, desired result, and a source URL before implementation begins.
