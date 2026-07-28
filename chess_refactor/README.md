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

人机对局加载统一的 AlphaZero 模型 `models/best_model.mat`，并通过 MCTS 选择走法。模型尚未经过长训练时，走法只用于验证流程，不代表棋力。

## AlphaZero Unified Full-Game Training

`+alphazero` 现在以标准开局为训练分布，维护唯一正式检查点：`models/best_model.mat`。完整开局网络使用保留棋盘空间位置的残差结构，和早期全局平均池化的残局验证网络不兼容；旧验证产物已移动到 `models/archive/endgame_validation/`。

训练使用十四通道局面编码、8100 动作策略头、合法动作掩码、PUCT MCTS、有界回放池和胜负/和棋价值目标。当前只从标准开局自我对弈；精选残局将等完整开局流程稳定后按可控比例混入同一个模型。

从 `chess_refactor` 目录运行一段训练：

```matlab
history = run_fullgame_segment(1)
```

训练可以跨天继续。每段会接续 `models/fullgame_progress.mat` 的轮次与随机状态，读取 `replay/fullgame/` 的回放，并将每轮指标追加到 `logs/fullgame/iteration_metrics.csv`。例如：

```matlab
history = run_fullgame_segment(20)
```

可用的分段预设为：

```matlab
settings = alphazero.fullgame_preset("short");
history = train_fullgame_alphazero(settings);
```

`short`、`medium`、`overnight` 分别为 2、10、30 轮可恢复段；先用 `run_fullgame_smoke` 做小规模验证。默认请求 GPU；本机的 CUDA 前向兼容会由训练入口自动启用。如需人工检查，在交互式 MATLAB 中运行：

```matlab
parallel.gpu.enableCUDAForwardCompatibility(true)
canUseGPU
```

当前实验使用根节点 Dirichlet 探索噪声、前 30 半回合按访问次数采样、64 次 MCTS、零和棋价值，以及 55% 的候选模型晋升线；评测和 GUI 不加探索噪声。此前陷入重复和棋的模型、回放与日志已删除，新的 GPU 冒烟轮从第 1 轮开始，耗时 7.3 秒、损失 3.6165、评测得分 0.500 且未晋升。它只验证数据流、检查点和恢复机制，不能说明模型棋力。

## Curated Endgame Challenges

The next training scope uses nine source-traceable, curated challenge positions: `七星聚会`, `马跃檀溪`, `炮炸两狼关`, `小征东`, `蚯蚓降龙`, `大九连环`, `带子入朝`, `征西`, and `野马操田`. Their coordinates and source commit are stored in `+alphazero/curated_scenarios.m` and the downloaded candidate data is retained under `references/classic_endgames/`.

These are curated scenarios rather than claims of uniquely canonical historical layouts. The shared model trains across all admitted scenarios, while self-play and candidate evaluation retain separate metrics for each scenario. Run the short all-scenario GPU data-flow check with:

```matlab
history = run_curated_smoke
```

Training can be split across multiple sessions. Each segment reuses `models/best_model.mat`, the bounded replay chunks, and `models/training_progress.mat`; replay file numbering and iteration numbers continue rather than restarting. For example, run a short segment today and another tomorrow:

```matlab
history = run_curated_segment(20)
```

On this machine, a GPU benchmark using nine games, four MCTS simulations per move, a 20-ply cap, one training step, and one evaluation game per scenario took 23.6 seconds end-to-end. It completed 105 self-play plies, or about 4.46 plies per second. This measures the current small-network implementation; use it to choose segment length, not as a chess-strength result.

Launch the endgame challenge interface with:

```matlab
run_endgame_challenge
```

挑战界面加载同一个 `models/best_model.mat`，提供九个精选残局，并使用 AlphaZero MCTS 作为 AI。玩家执红；八个残局以红方获胜为目标，`蚯蚓降龙`以和棋为目标。普通 `run_gui` 人机模式也使用这个检查点。

## Rule Coverage

Implemented: normal opening, all piece movement rules, palace and river restrictions, horse-leg and elephant-eye blocking, cannon screens, flying generals, self-check prevention, checkmate/stalemate detection, captured-general compatibility, and threefold repetition detection.

Not implemented: official long-check/long-chase adjudication and formal move-clock draw rules.

## Next Training Scope

Full-game self-play is now the active path. Before starting a long segment, confirm `canUseGPU` interactively, run `run_fullgame_smoke`, and inspect `logs/fullgame/iteration_metrics.csv`. The next planned model change is not a separate endgame model: it is a measured sampling ratio that mixes the curated endgames into the same unified replay distribution, with opening and endgame evaluation reported separately.

## Important Rule

Do not edit the parent-directory original project. Make every future code change in this `chess_refactor` directory.
