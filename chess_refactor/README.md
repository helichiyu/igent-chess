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

On this development machine, MATLAB R2024b is installed at:

```text
G:\Matlab2024b\bin\matlab.exe
```

From PowerShell, the test suite can be run with:

```powershell
& "G:\Matlab2024b\bin\matlab.exe" -batch "cd('E:\matlab\project\chess_refactor'); run_tests"
```

The front end is fully Chinese. Select a game mode, then click one of your pieces and click a green legal-move marker to move it.

The AI first attempts to load `model5.mat` if you explicitly place a compatible model in this directory. Without a model it uses a deterministic material-and-capture heuristic, so the GUI remains usable.

## AlphaZero Endgame Validation

The `+alphazero` package implements a small AlphaZero-style validation experiment. It is intentionally limited to fixed positions with both generals and one red rook. It is not a full-game or tournament-strength engine.

The pipeline uses the `xiangqi` rule engine, a fourteen-plane current-player state encoding, an 8100-action policy head, legal-action masking, PUCT MCTS, bounded replay data, and a shared policy-value network. The network is trained on MCTS root-visit policies and final game outcomes.

Run a small experiment from the `chess_refactor` folder:

```matlab
history = train_endgame_alphazero
```

The default configuration requests GPU execution. Confirm GPU availability first with `canUseGPU`; set `useGPU` to `false` only for CPU debugging:

```matlab
history = train_endgame_alphazero(struct("useGPU", false, "iterations", 1));
```

This machine's GPU requires MATLAB CUDA forward compatibility. The training entry point enables it automatically when needed. In an interactive MATLAB session, enable it before manually checking `canUseGPU`:

```matlab
parallel.gpu.enableCUDAForwardCompatibility(true)
canUseGPU
```

Default artifacts are written to `chess_refactor/models/best_model.mat` and `chess_refactor/replay/`. These generated directories are excluded from source control. The GUI still uses its existing heuristic/model selector; AlphaZero GUI selection is intentionally deferred until the training loop has been evaluated beyond the small validation scope.

## Curated Endgame Challenges

The next training scope uses nine source-traceable, curated challenge positions: `七星聚会`, `马跃檀溪`, `炮炸两狼关`, `小征东`, `蚯蚓降龙`, `大九连环`, `带子入朝`, `征西`, and `野马操田`. Their coordinates and source commit are stored in `+alphazero/curated_scenarios.m` and the downloaded candidate data is retained under `references/classic_endgames/`.

These are curated scenarios rather than claims of uniquely canonical historical layouts. The shared model trains across all admitted scenarios, while self-play and candidate evaluation retain separate metrics for each scenario. Run the short all-scenario GPU data-flow check with:

```matlab
history = run_curated_smoke
```

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
