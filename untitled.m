% 商人随从过河问题 - 修正版
clear; clc;

% 参数设置
N = 3; % 商人和随从的数量
C = 2; % 船的容量

% 初始状态：[左岸商人数, 左岸随从数, 船的位置（0左岸, 1右岸）]
startState = [N, N, 0];
goalState = [0, 0, 1];

% 生成所有可能的移动决策（船上商人数u，随从数v）
D = [];
for u = 0:C
    for v = 0:(C - u)
        if u + v >= 1 && u + v <= C % 船上至少1人，最多C人
            D = [D; u, v];
        end
    end
end
% D 包含所有合法决策，如[1,0], [0,1], [2,0], [0,2], [1,1]

% 安全性检查函数
isSafe = @(M_left, S_left, total) ...
    (M_left >= 0 && S_left >= 0 && ... % 左岸人数非负
    (total - M_left) >= 0 && (total - S_left) >= 0 && ... % 右岸人数非负
    (M_left == 0 || M_left >= S_left) && ... % 左岸安全：商人不少于随从或商人数为0
    ((total - M_left) == 0 || (total - M_left) >= (total - S_left))); % 右岸安全

% 初始化BFS队列
% 队列结构：每个元素为 {当前状态, 路径历史}
queue = { {startState, {startState}} };
% 使用Map记录已访问的状态，避免重复
visited = containers.Map();
visited(mat2str(startState)) = 1;

solutionFound = false;
solutionPath = {};

fprintf('开始搜索安全渡河方案...\n');

while ~isempty(queue)
    % 取出队列首元素
    currentCell = queue{1};
    currentState = currentCell{1};
    currentPath = currentCell{2};
    queue(1) = []; % 移除已处理项
    
    % 判断是否到达目标状态
    if isequal(currentState, goalState)
        solutionFound = true;
        solutionPath = currentPath;
        break;
    end
    
    % 生成所有可能的下一步状态
    x = currentState(1); % 左岸商人数
    y = currentState(2); % 左岸随从数
    b = currentState(3); % 船的位置
    
    for i = 1:size(D, 1)
        d = D(i, :); % 当前决策 [u, v]
        u = d(1); % 船上的商人数
        v = d(2); % 船上的随从数
        
        % 关键修改1：检查当前岸是否有足够的人进行此移动
        if b == 0 % 船在左岸
            available_M = x;
            available_S = y;
        else % 船在右岸
            available_M = N - x;
            available_S = N - y;
        end
        
        % 如果当前岸没有足够的商人数或随从数，跳过此移动
        if u > available_M || v > available_S
            continue;
        end
        
        % 关键修改2：根据船的位置决定状态转移方向
        if b == 0 % 船在左岸，向右岸运人
            newState = [x - u, y - v, 1];
        else % 船在右岸，向左岸运人
            newState = [x + u, y + v, 0];
        end
        
        % 检查新状态是否在合法范围内
        if newState(1) >= 0 && newState(1) <= N && ...
           newState(2) >= 0 && newState(2) <= N
            
            % 关键修改3：实时检查新状态的安全性
            if isSafe(newState(1), newState(2), N)
                key = mat2str(newState);
                
                % 如果新状态未被访问过，加入队列
                if ~isKey(visited, key)
                    visited(key) = 1;
                    newPath = [currentPath, newState];
                    queue{end+1} = {newState, newPath};
                end
            end
        end
    end
end

% 输出结果
if solutionFound
    fprintf('\n安全渡河方案找到（共%d步）：\n', length(solutionPath)-1);
    fprintf('步骤\t左岸(商,随)\t右岸(商,随)\t船位\t行动描述\n');
    fprintf('----------------------------------------------------------------\n');
    
    for step = 1:length(solutionPath)
        state = solutionPath{step};
        left_merchants = state(1);
        left_servants = state(2);
        right_merchants = N - state(1);
        right_servants = N - state(2);
        boat_pos = state(3);
        
        if step == 1
            action = '初始状态';
        else
            prev_state = solutionPath{step-1};
            % 计算移动差异
            m_move = abs(state(1) - prev_state(1));
            s_move = abs(state(2) - prev_state(2));
            direction = ifelse(prev_state(3) == 0, '左岸→右岸', '右岸→左岸');
            action = sprintf('运送 %d商,%d随 %s', m_move, s_move, direction);
        end
        
        boat_shore = ifelse(boat_pos == 0, '左岸', '右岸');
        fprintf('%2d\t\t(%d, %d)\t\t(%d, %d)\t\t%s\t%s\n', ...
                step-1, left_merchants, left_servants, ...
                right_merchants, right_servants, boat_shore, action);
    end
else
    fprintf('未找到安全渡河方案！\n');
end

% 辅助函数：简化条件判断
function result = ifelse(condition, trueValue, falseValue)
    if condition
        result = trueValue;
    else
        result = falseValue;
    end
end