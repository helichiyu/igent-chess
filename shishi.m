if isfile('model5.mat')
    delete('model5.mat');
    disp('删除成功')
else
    disp('未找到文件')
end