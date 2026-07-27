function outcome = play_game(redNet, blackNet, position, settings)
%PLAY_GAME Play one deterministic evaluation game from a fixed position.
state = alphazero.new_state(position.board, position.player, settings.maxPlies);
root = [];
while true
    outcome = alphazero.game_state(state);
    if outcome.isOver
        return;
    end
    net = redNet;
    if state.player == -1
        net = blackNet;
    end
    [move, ~, root] = alphazero.mcts_search(net, state, settings, root);
    edge = find(ismember(root.Moves, move, "rows"), 1);
    if isempty(edge)
        error("alphazero:InvalidSearchMove", "MCTS returned a move outside the root.");
    end
    if isempty(root.Children{edge})
        root.Children{edge} = alphazero.MCTSNode(alphazero.next_state(state, move));
    end
    root = root.Children{edge};
    state = root.State;
end
end
