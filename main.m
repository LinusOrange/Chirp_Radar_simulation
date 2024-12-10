% 清空工作区
clear; clc; close all;

%% 1. 仿真参数设置

% 雷达参数
f0 = 1e9;        % 起始频率 1 GHz
B = 20e6;        % 带宽 20 MHz
T = 10e-6;       % 信号持续时间 10 微秒
A = 1;           % 信号幅度
c = 3e8;         % 光速 3e8 m/s
SNR_dB = 20;     % 信噪比 20 dB

% 采样参数
Fs = 1 / 1e-9;            % 采样率 1 GHz
t = 0:1/Fs:T;             % 时间向量，从0到T，步长为1/Fs

% 仿真时间
T_total = 100;    % 总仿真时间，100秒

% 初始化存储变量
actual_range = zeros(T_total, 1);
actual_velocity = zeros(T_total, 1);
estimated_range = zeros(T_total, 1);
estimated_velocity = zeros(T_total, 1);

% 初始化目标状态
last_position = [0, 0];  % 上一秒的笛卡尔坐标位置 [x, y]，初始为 [0, 0] 米
last_velocity = [0, 0];  % 上一秒的速度 [vx, vy]，初始为 [0, 0] 米/秒

% 初始化图形窗口
figure;
subplot(2,1,1);
hold on;
axis equal;
xlim([-2000, 2000]);  % 设置x轴范围
ylim([-2000, 2000]);  % 设置y轴范围
xlabel('X 位置 (米)');
ylabel('Y 位置 (米)');
title('目标运动轨迹（笛卡尔坐标）');
grid on;

% 目标轨迹的绘制
h_target_cartesian = plot(NaN, NaN, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % 绘制目标位置的点
h_trajectory_cartesian = plot(NaN, NaN, 'b-', 'LineWidth', 1);  % 绘制轨迹线

subplot(2,1,2);
hold on;
xlim([0, T_total]);     % 设置时间轴范围
ylim([0, 3000]);        % 设置距离范围
xlabel('时间 (秒)');
ylabel('距离 (米)');
title('目标距离变化');
grid on;

% 测距结果的绘制
h_distance = plot(NaN, NaN, 'g-', 'LineWidth', 2);  % 绘制测距结果

%% 2. 仿真循环

for t_sec = 1:T_total
    % 2.1 更新目标位置和速度
    [position_polar, velocity, angle] = generate_random_target(t_sec, last_position, last_velocity);
    
    % 转换回笛卡尔坐标
    position_cartesian = [position_polar(1)*cosd(position_polar(2)), position_polar(1)*sind(position_polar(2))];
    
    % 存储实际距离和速度
    actual_range(t_sec) = position_polar(1);
    % 计算径向速度
    unit_vector = [cosd(position_polar(2)), sind(position_polar(2))];
    radial_velocity = dot(velocity, unit_vector);
    actual_velocity(t_sec) = radial_velocity;
    
    % 2.2 生成发射信号
    chirp_signal = generate_chirp_signal(f0, B, T, A, t);
    
    % 2.3 生成回波信号
    echo_signal = generate_echo_signal(chirp_signal, position_polar, velocity, t, c, f0, B, SNR_dB);
    
    % 2.4 处理回波信号，提取距离和速度
    [est_range, est_velocity] = process_echo_signal(chirp_signal, echo_signal, f0, B, T, c, Fs);
    
    % 存储估算的距离和速度
    estimated_range(t_sec) = est_range;
    estimated_velocity(t_sec) = est_velocity;
    
    % 2.5 更新最后的位置和速度
    last_position = position_cartesian;
    last_velocity = velocity;
    
    % 2.6 更新笛卡尔坐标图
    subplot(2,1,1);
    set(h_target_cartesian, 'XData', position_cartesian(1), 'YData', position_cartesian(2));
    
    if t_sec == 1
        trajectory_x = position_cartesian(1);
        trajectory_y = position_cartesian(2);
    else
        trajectory_x(end+1) = position_cartesian(1);
        trajectory_y(end+1) = position_cartesian(2);
    end
    set(h_trajectory_cartesian, 'XData', trajectory_x, 'YData', trajectory_y);
    
    % 2.7 更新距离图
    subplot(2,1,2);
    set(h_distance, 'XData', 1:t_sec, 'YData', actual_range(1:t_sec));
    
    % 2.8 刷新图形窗口
    drawnow;
    
    % 2.9 暂停以控制动画播放速度
    pause(0.05);  % 可根据需要调整
end

%% 3. 显示和记录结果

% 创建一个表格，包含时间、实际距离、实际速度、估算距离、估算速度
results_table = table((1:T_total)', actual_range, actual_velocity, estimated_range, estimated_velocity, ...
                      'VariableNames', {'时间_s', '实际距离_m', '实际速度_m_s', '估算距离_m', '估算速度_m_s'});

% 显示前几行结果
disp('仿真结果（前10秒）：');
disp(head(results_table, 10));

% 计算误差
range_error = estimated_range - actual_range;
velocity_error = estimated_velocity - actual_velocity;

% 绘制距离误差
figure;
subplot(2,1,1);
plot(1:T_total, range_error, 'm');
title('距离估算误差');
xlabel('时间 (秒)');
ylabel('误差 (米)');
grid on;

% 绘制速度误差
subplot(2,1,2);
plot(1:T_total, velocity_error, 'c');
title('速度估算误差');
xlabel('时间 (秒)');
ylabel('误差 (米/秒)');
grid on;

% 绘制实际距离与估算距离对比
figure;
plot(1:T_total, actual_range, 'b-', 'LineWidth', 1.5);
hold on;
plot(1:T_total, estimated_range, 'r--', 'LineWidth', 1.5);
title('实际距离与估算距离对比');
xlabel('时间 (秒)');
ylabel('距离 (米)');
legend('实际距离', '估算距离');
grid on;

% 绘制实际速度与估算速度对比
figure;
plot(1:T_total, actual_velocity, 'b-', 'LineWidth', 1.5);
hold on;
plot(1:T_total, estimated_velocity, 'r--', 'LineWidth', 1.5);
title('实际速度与估算速度对比');
xlabel('时间 (秒)');
ylabel('速度 (米/秒)');
legend('实际速度', '估算速度');
grid on;
