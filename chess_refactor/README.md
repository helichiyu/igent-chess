# Chinese Chess Refactor Working Copy

## Origin and Scope

This directory is a working copy of the original hand-written MATLAB Chinese chess project, created on 2026-07-27.

The original files in the parent directory are preserved for commemorative reasons and must not be modified. All repairs, refactoring, tests, and experimental changes belong only in this directory.

## Current Implementation

Only the new implementation is retained here. The historical copied source files and model files were removed from this working directory; the commemorative originals remain unchanged in the parent directory.

- `run_gui.m`: graphical human-vs-human and human-vs-AI entry point.
- `+xiangqi/`: board setup, movement rules, check detection, legal move filtering, game-state logic, and AI move selection.
- `tests/`: `matlab.unittest` coverage for essential piece rules and illegal self-check moves.
- `run_tests.m`: test entry point.

## Running

Open this directory as the MATLAB current folder, then run:

```matlab
run_gui
run_tests
```

The front end is fully Chinese. Select a game mode, then click one of your pieces and click a green legal-move marker to move it.

The AI first attempts to load `model5.mat` if you explicitly place a compatible model in this directory. Without a model it uses a deterministic material-and-capture heuristic, so the GUI remains usable.

## Rule Coverage

Implemented: normal opening, all piece movement rules, palace and river restrictions, horse-leg and elephant-eye blocking, cannon screens, flying generals, self-check prevention, checkmate/stalemate detection, captured-general compatibility, and threefold repetition detection.

Not implemented: official long-check/long-chase adjudication and formal move-clock draw rules.

## AlphaZero Endgame Training Roadmap

AlphaZero-style training remains a planned feature, but it will not begin with full-game self-play. Full Chinese-chess training has a very large state space and is impractical as a first target.

The planned order is:

1. Build a reproducible endgame-position format and a legal-move/game-result data pipeline.
2. Train and evaluate separate small models on classical Chinese-chess endgames, starting with material-simple positions such as king-and-rook, king-and-cannon, king-and-pawn, and commonly studied practical endgame patterns.
3. Add MCTS with policy and value heads, limited to one endgame category at a time.
4. Verify against tablebase-like solved positions, curated classical examples, and fixed tactical test suites.
5. Gradually combine validated endgame specialists before considering broader full-game self-play.

The future training implementation should be added as new modules (for example `train_endgame_alphazero.m`) and must not reintroduce the old unlimited self-play data accumulation approach.

## Important Rule

Do not edit the parent-directory original project. Make every future code change in this `chess_refactor` directory.
