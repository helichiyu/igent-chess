function run_gui()
%RUN_GUI Start the refactored Chinese-chess GUI.
fig = figure("Name", "Chinese Chess", "NumberTitle", "off", ...
    "MenuBar", "none", "ToolBar", "none", "Position", [300 120 760 650], ...
    "WindowButtonDownFcn", @board_click, "Color", [0.94 0.90 0.80]);
ax = axes("Parent", fig, "Position", [0.05 0.10 0.62 0.84], ...
    "YDir", "reverse", "XLim", [0.5 9.5], "YLim", [0.5 10.5], ...
    "XTick", 1:9, "YTick", 1:10, "Box", "on", "Color", [0.94 0.90 0.80]);
hold(ax, "on");
textHandles = gobjects(10, 9);
squareHandles = gobjects(10, 9);
for row = 1:10
    for col = 1:9
        squareHandles(row, col) = rectangle(ax, "Position", [col-.5 row-.5 1 1], ...
            "FaceColor", "none", "EdgeColor", [0.35 0.20 0.10]);
        textHandles(row, col) = text(ax, col, row, "", "HorizontalAlignment", "center", ...
            "VerticalAlignment", "middle", "FontSize", 20, "FontWeight", "bold");
    end
end
uicontrol(fig, "Style", "pushbutton", "String", "New human game", ...
    "Position", [535 560 170 36], "Callback", @(~, ~)reset_game("human"));
uicontrol(fig, "Style", "pushbutton", "String", "Play as red", ...
    "Position", [535 510 170 36], "Callback", @(~, ~)reset_game("ai_red"));
uicontrol(fig, "Style", "pushbutton", "String", "Play as black", ...
    "Position", [535 460 170 36], "Callback", @(~, ~)reset_game("ai_black"));
uicontrol(fig, "Style", "pushbutton", "String", "Restart", ...
    "Position", [535 410 170 36], "Callback", @(~, ~)reset_game(current_mode()));
status = uicontrol(fig, "Style", "text", "Position", [515 150 210 230], ...
    "HorizontalAlignment", "left", "BackgroundColor", get(fig, "Color"), ...
    "FontSize", 11, "String", "Choose a game mode.");
state = struct("board", xiangqi.new_board(), "player", 1, "mode", "human", ...
    "humanPlayer", 0, "selected", zeros(0, 2), "targetHandles", gobjects(0), ...
    "textHandles", textHandles, "squareHandles", squareHandles, "status", status, ...
    "positionCounts", new_counts(), "isOver", false, "lastMove", zeros(0, 4));
guidata(fig, state);
reset_game("human");

    function mode = current_mode()
        data = guidata(fig);
        mode = data.mode;
    end

    function reset_game(mode)
        data = guidata(fig);
        data.board = xiangqi.new_board();
        data.player = 1;
        data.mode = mode;
        data.selected = zeros(0, 2);
        data.targetHandles = gobjects(0);
        data.positionCounts = new_counts();
        data.positionCounts(char(xiangqi.position_key(data.board, data.player))) = 1;
        data.isOver = false;
        data.lastMove = zeros(0, 4);
        if strcmp(mode, "ai_red")
            data.humanPlayer = 1;
        elseif strcmp(mode, "ai_black")
            data.humanPlayer = -1;
        else
            data.humanPlayer = 0;
        end
        guidata(fig, data);
        render();
        if data.mode ~= "human" && data.player ~= data.humanPlayer
            perform_ai_move();
        end
    end

    function board_click(~, ~)
        data = guidata(fig);
        if data.isOver || (data.mode ~= "human" && data.player ~= data.humanPlayer)
            return;
        end
        point = get(ax, "CurrentPoint");
        col = round(point(1, 1));
        row = round(point(1, 2));
        if row < 1 || row > 10 || col < 1 || col > 9
            return;
        end
        if isempty(data.selected)
            if belongs_to_player(data.board(row, col), data.player)
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
        moves = xiangqi.legal_moves(data.board, data.player);
        candidate = [data.selected row col];
        if any(ismember(moves, candidate, "rows"))
            commit_move(candidate);
            data = guidata(fig);
            if ~data.isOver && data.mode ~= "human"
                perform_ai_move();
            end
        elseif belongs_to_player(data.board(row, col), data.player)
            data.selected = [row col];
            guidata(fig, data);
            render();
        end
    end

    function perform_ai_move()
        data = guidata(fig);
        if data.isOver, return; end
        set(data.status, "String", "AI is thinking...");
        drawnow;
        [move, detail] = xiangqi.choose_move(data.board, data.player, "model5.mat");
        if isempty(move)
            finish_turn();
            return;
        end
        commit_move(move, detail);
    end

    function commit_move(move, detail)
        if nargin < 2, detail = struct("source", "human", "modelError", ""); end
        data = guidata(fig);
        data.board = xiangqi.apply_move(data.board, move);
        data.lastMove = move;
        data.selected = zeros(0, 2);
        data.player = xiangqi.opponent(data.player);
        key = char(xiangqi.position_key(data.board, data.player));
        if isKey(data.positionCounts, key)
            data.positionCounts(key) = data.positionCounts(key) + 1;
        else
            data.positionCounts(key) = 1;
        end
        guidata(fig, data);
        finish_turn(detail);
    end

    function finish_turn(detail)
        if nargin < 1, detail = struct("source", "", "modelError", ""); end
        data = guidata(fig);
        outcome = xiangqi.game_state(data.board, data.player, data.positionCounts);
        data.isOver = outcome.isOver;
        guidata(fig, data);
        render(detail, outcome);
    end

    function render(detail, outcome)
        if nargin < 1, detail = struct("source", "", "modelError", ""); end
        if nargin < 2
            data = guidata(fig);
            outcome = xiangqi.game_state(data.board, data.player, data.positionCounts);
        end
        data = guidata(fig);
        clear_targets(data);
        for row = 1:10
            for col = 1:9
                piece = data.board(row, col);
                if piece == 0
                    set(data.textHandles(row, col), "String", "");
                else
                    color = [0.75 0.05 0.05];
                    if piece >= 8, color = [0.05 0.05 0.05]; end
                    set(data.textHandles(row, col), "String", char(xiangqi.piece_name(piece)), "Color", color);
                end
                set(data.squareHandles(row, col), "FaceColor", "none");
            end
        end
        if ~isempty(data.lastMove)
            set(data.squareHandles(data.lastMove(3), data.lastMove(4)), "FaceColor", [0.75 0.85 0.60]);
        end
        if ~isempty(data.selected) && ~data.isOver
            set(data.squareHandles(data.selected(1), data.selected(2)), "FaceColor", [1 0.9 0.25]);
            legal = xiangqi.legal_moves(data.board, data.player);
            targets = legal(legal(:, 1) == data.selected(1) & legal(:, 2) == data.selected(2), 3:4);
            data.targetHandles = gobjects(size(targets, 1), 1);
            for index = 1:size(targets, 1)
                data.targetHandles(index) = scatter(ax, targets(index, 2), targets(index, 1), 90, ...
                    "filled", "MarkerFaceColor", [0.15 0.55 0.20], "MarkerEdgeColor", "w");
            end
            guidata(fig, data);
        end
        if outcome.isOver
            if outcome.winner == 1, winner = "Red wins";
            elseif outcome.winner == -1, winner = "Black wins";
            else, winner = "Draw"; end
            message = sprintf("%s\nReason: %s\nStart a new game to continue.", winner, outcome.result);
        else
            side = "Red";
            if data.player == -1, side = "Black"; end
            message = sprintf("%s to move", side);
            if outcome.inCheck, message = message + " (in check)"; end
            if ~isempty(data.lastMove), message = message + "\nLast move completed"; end
            if detail.source == "heuristic", message = message + "\nAI: heuristic fallback"; end
        end
        set(data.status, "String", message);
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

function counts = new_counts()
counts = containers.Map("KeyType", "char", "ValueType", "double");
end
