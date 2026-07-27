function name = piece_name(piece)
%PIECE_NAME Return the display character for a piece code.
names = ["帅" "仕" "相" "马" "车" "炮" "兵" ...
         "将" "士" "象" "马" "车" "炮" "卒"];
if piece < 1 || piece > numel(names)
    name = "";
else
    name = names(piece);
end
end
