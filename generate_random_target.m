function [position_polar, velocity, angle] = generate_random_target(t, last_position, last_velocity)
    % 生成目标的位置和速度，并计算新的目标位置（极坐标）
    % 输入：
    % t             - 当前时间（秒），每次调用时时间递增
    % last_position - 上一秒目标的位置 [x, y]（米）
    % last_velocity - 上一秒目标的速度 [vx, vy]（米/秒）
    %
    % 输出：
    % position_polar - 目标的当前位置 [r, theta]（极坐标，米，度）
    % velocity        - 目标的速度 [vx, vy]（米/秒）
    % angle           - 目标相对于雷达原点的方向角（度）

    if t == 1
        % 第一秒时，随机生成目标的初始位置和速度
        x = rand * 2000 - 1000;  % 随机生成初始x位置 [-1000, 1000] 米
        y = rand * 2000 - 1000;  % 随机生成初始y位置 [-1000, 1000] 米
        position_cartesian = [x, y];
        velocity = [rand * 20 - 10, rand * 20 - 10];  % 随机生成初速度 [vx, vy] [-10, 10] 米/秒
    else
        % 从上一秒的状态计算位置，施加随机加速度以更新速度
        % 定义加速度范围
        a_max = 2;    % 最大加速度 2 m/s²
        a_min = -2;   % 最小加速度 -2 m/s²
        
        % 生成随机加速度
        acceleration = [rand * (a_max - a_min) + a_min, rand * (a_max - a_min) + a_min];  % [ax, ay] m/s²
        
        % 更新速度
        velocity = last_velocity + acceleration;  % 速度更新
        
        % 更新位置
        position_cartesian = last_position + velocity;  % 假设时间步长为1秒
    end

    % 计算目标相对于雷达原点的极坐标位置
    r = norm(position_cartesian);                            % 计算欧几里得距离
    theta = atan2d(position_cartesian(2), position_cartesian(1));  % 计算角度（度）

    % 返回极坐标位置，速度，以及角度
    position_polar = [r, theta];
    angle = theta;
end
