function run_endgame_challenge()
%RUN_ENDGAME_CHALLENGE Launch the curated endgame challenge GUI.
scenarios = alphazero.curated_scenarios();
projectRoot = fileparts(mfilename("fullpath"));
modelPath = fullfile(projectRoot, "models", "best_model.mat");

fig = figure("Name", "残局挑战", "NumberTitle", "off", ...
    "MenuBar", "none", "ToolBar", "none", "Position", [300 120 900 650], ...
    "WindowButtonDownFcn", @board_click, "Color", [0.94 0.90 0.80]);
ax = axes("Parent", fig, "Position", [0.05 0.10 0.55 0.84], ...
    "YDir", "reverse", "XLim", [0.5 9.5], "YLim", [0.5 10.5], ...
    "XTick", 1:9, "YTick", 1:10, "Box", "on", "Color", [0.94 0.90 0.80]);
hold(ax, "on");
textHandles = gobjects(10, 9);
squareHandles = gobjects(10, 9);
for row = 1:10
    for col = 1:9
        squareHandles(row, col) = rectangle(ax, "Position", [col-.5 row-.5 1 1], ...
            "FaceColor", "none", "EdgeColor", [0.35 0.20 0.10], ...
            "ButtonDownFcn", @board_click);
        textHandles(row, col) = text(ax, col, row, "", ...
            "HorizontalAlignment", "center", "VerticalAlignment", "middle", ...
            "FontSize", 20, "FontWeight", "bold", "HitTest", "off");
    end
end
uicontrol(fig, "Style", "text", "String", "残局选择", ...
    "Position", [625 570 220 20], "BackgroundColor", get(fig, "Color"));
scenarioPicker = uicontrol(fig, "Style", "popupmenu", ...
    "String", cellstr(string({scenarios.name})), "Position", [625 545 220 28]);
uicontrol(fig, "Style", "pushbutton", "String", "开始挑战", ...
    "Position", [625 500 220 36], "Callback", @start_challenge);
uicontrol(fig, "Style", "pushbutton", "String", "重新开始", ...
    "Position", [625 455 220 36], "Callback", @restart_challenge);
status = uicontrol(fig, "Style", "text", "Position", [620 145 235 280], ...
    "HorizontalAlignment", "left", "BackgroundColor", get(fig, "Color"), ...
    "FontSize", 11, "String", "请选择残局后开始挑战。");

state = struct("challenge", [], "net", [], "settings", [], "metadata", struct(), ...
    "selected", zeros(0, 2), ...
    "targetHandles", gobjects(0), "textHandles", textHandles, ...
    "squareHandles", squareHandles, "status", status);
guidata(fig, state);

    function start_challenge(~, ~)
        index = get(scenarioPicker, "Value");
        if ~isfile(modelPath)
            set(status, "String", "未找到训练模型：models/best_model.mat");
            return;
        end
        try
            [net, metadata, settings] = alphazero.load_unified_model();
            alphazero.prepare_execution(settings);
        catch exception
            %#ok<NASGU>
            set(status, "String", "统一模型加载失败，请检查 models/best_model.mat。");
            return;
        end
        data = guidata(fig);
        data.challenge = alphazero.new_challenge_state(scenarios(index));
        data.net = net;
        data.settings = settings;
        data.metadata = metadata;
        data.selected = zeros(0, 2);
        data.targetHandles = gobjects(0);
        guidata(fig, data);
        render();
        if data.challenge.player ~= data.challenge.humanPlayer
            perform_ai_move();
        end
    end

    function restart_challenge(~, ~)
        data = guidata(fig);
        if isempty(data.challenge)
            start_challenge([], []);
            return;
        end
        index = get(scenarioPicker, "Value");
        data.challenge = alphazero.new_challenge_state(scenarios(index));
        data.selected = zeros(0, 2);
        data.targetHandles = gobjects(0);
        guidata(fig, data);
        render();
    end

    function board_click(~, ~)
        data = guidata(fig);
        if isempty(data.challenge) || data.challenge.isOver || ...
                data.challenge.player ~= data.challenge.humanPlayer
            return;
        end
        point = get(ax, "CurrentPoint");
        col = round(point(1, 1));
        row = round(point(1, 2));
        if row < 1 || row > 10 || col < 1 || col > 9
            return;
        end
        if isempty(data.selected)
            if belongs_to_player(data.challenge.board(row, col), data.challenge.player)
                data.selected = [row col];
                guidata(fig, data);
                render();
            end
            return;
        end
        if isequal(data.selected, [row col])
            data.selected = zeros(0, 2);
            guidata(fig, data);
            render();
            return;
        end
        moves = xiangqi.legal_moves(data.challenge.board, data.challenge.player);
        move = [data.selected row col];
        if any(ismember(moves, move, "rows"))
            commit_move(move, "human");
            data = guidata(fig);
            if ~data.challenge.isOver
                perform_ai_move();
            end
        elseif belongs_to_player(data.challenge.board(row, col), data.challenge.player)
            data.selected = [row col];
            guidata(fig, data);
            render();
        end
    end

    function perform_ai_move()
        data = guidata(fig);
        if data.challenge.isOver
            return;
        end
        set(status, "String", "电脑正在使用蒙特卡洛树搜索...");
        drawnow;
        [move, ~] = alphazero.mcts_search(data.net, data.challenge, data.settings);
        if isempty(move)
            finish_turn("统一模型搜索");
            return;
        end
        commit_move(move, "统一模型搜索");
    end

    function commit_move(move, source)
        data = guidata(fig);
        data.challenge = alphazero.next_challenge_state(data.challenge, move);
        data.selected = zeros(0, 2);
        guidata(fig, data);
        finish_turn(source);
    end

    function finish_turn(source)
        data = guidata(fig);
        outcome = alphazero.game_state(data.challenge);
        data.challenge.isOver = outcome.isOver;
        guidata(fig, data);
        render(source, outcome);
    end

    function render(source, outcome)
        if nargin < 1, source = ""; end
        data = guidata(fig);
        if nargin < 2
            outcome = alphazero.game_state(data.challenge);
        end
        clear_targets(data);
        for row = 1:10
            for col = 1:9
                piece = data.challenge.board(row, col);
                if piece == 0
                    set(data.textHandles(row, col), "String", "");
                else
                    color = [0.75 0.05 0.05];
                    if piece >= 8, color = [0.05 0.05 0.05]; end
                    set(data.textHandles(row, col), "String", ...
                        char(xiangqi.piece_name(piece)), "Color", color);
                end
                set(data.squareHandles(row, col), "FaceColor", "none");
            end
        end
        if ~isempty(data.challenge.lastMove)
            move = data.challenge.lastMove;
            set(data.squareHandles(move(3), move(4)), "FaceColor", [0.75 0.85 0.60]);
        end
        if ~data.challenge.isOver && ~isempty(data.selected)
            set(data.squareHandles(data.selected(1), data.selected(2)), ...
                "FaceColor", [1 0.9 0.25]);
            legal = xiangqi.legal_moves(data.challenge.board, data.challenge.player);
            targets = legal(legal(:, 1) == data.selected(1) & ...
                legal(:, 2) == data.selected(2), 3:4);
            data.targetHandles = gobjects(size(targets, 1), 1);
            for index = 1:size(targets, 1)
                data.targetHandles(index) = scatter(ax, targets(index, 2), targets(index, 1), ...
                    90, "filled", "MarkerFaceColor", [0.15 0.55 0.20], ...
                    "MarkerEdgeColor", "w", "HitTest", "off");
            end
            guidata(fig, data);
        end
        if data.challenge.isOver
            if alphazero.challenge_succeeded(data.challenge.scenario, outcome)
                result = "挑战成功。";
            else
                result = "挑战失败。";
            end
            message = sprintf("%s\n结果：%s\n结束原因：%s\n请点击“重新开始”再次挑战。", ...
                result, winner_text(outcome.winner), outcome.result);
        else
            side = "红方";
            if data.challenge.player == -1, side = "黑方"; end
            message = sprintf("%s\n目标：%s\n回合：%d/%d\n轮到：%s\n模型：%s", ...
                data.challenge.scenario.name, goal_text(data.challenge.scenario.expectedResult), ...
                data.challenge.ply, data.challenge.maxPlies, side, ...
                data.metadata.networkVersion);
            if outcome.inCheck, message = message + "（被将军）"; end
            if source == "统一模型搜索", message = message + "\n电脑：统一模型搜索"; end
        end
        set(status, "String", message);
        drawnow;
    end

    function clear_targets(data)
        if ~isempty(data.targetHandles)
            valid = isgraphics(data.targetHandles);
            delete(data.targetHandles(valid));
            data.targetHandles = gobjects(0);
            guidata(fig, data);
        end
    end
end

function result = belongs_to_player(piece, player)
result = (player == 1 && piece >= 1 && piece <= 7) || ...
    (player == -1 && piece >= 8 && piece <= 14);
end

function text = goal_text(expectedResult)
if expectedResult == "draw"
    text = "和棋";
elseif expectedResult == "red_win"
    text = "红方胜";
else
    text = "黑方胜";
end
end

function text = winner_text(winner)
if winner == 1
    text = "红方胜";
elseif winner == -1
    text = "黑方胜";
else
    text = "和棋";
end
end
