function echo_signal = generate_echo_signal(chirp_signal, position_polar, velocity, t, c, f0, B, SNR_dB)
    % 生成带有噪声的目标回波信号（二维空间）
    % 输入：
    % chirp_signal   - 发射的Chirp信号（向量）
    % position_polar - 目标当前位置 [r, theta]（极坐标，米，度）
    % velocity       - 目标速度 [vx, vy]（米/秒）
    % t              - 时间向量 (秒)
    % c              - 光速 (m/s)
    % f0             - 发射信号的起始频率 (Hz)
    % B              - 信号的带宽 (Hz)
    % SNR_dB         - 信噪比 (dB)
    %
    % 输出：
    % echo_signal    - 带有噪声的目标回波信号（向量）

    % 提取极坐标位置
    r = position_polar(1);
    theta = position_polar(2);
    
    % 计算传播延迟（两倍距离除以光速）
    t_delay = 2 * r / c;
    
    % 计算径向速度（速度在雷达方向的分量）
    unit_vector = [cosd(theta), sind(theta)];       % 单位向量
    radial_velocity = dot(velocity, unit_vector);   % 径向速度
    
    % 计算多普勒频移
    f_doppler = (2 * radial_velocity * f0) / c;     % 多普勒频移公式
    
    % 应用多普勒频移：频率偏移
    doppler_shifted_signal = chirp_signal .* exp(1j * 2 * pi * f_doppler * t);
    
    % 应用时间延迟：使用插值处理分数延迟
    t_echo = t - t_delay;
    echo_signal = zeros(size(chirp_signal));        % 初始化回波信号
    
    % 有效的回波时间索引
    valid_idx = t_echo >= 0 & t_echo <= max(t);
    
    % 插值生成延迟后的信号
    echo_signal(valid_idx) = real(interp1(t, doppler_shifted_signal, t_echo(valid_idx), 'linear', 0));
    
    % 添加高斯白噪声（AWGN）
    echo_signal_noisy = awgn(echo_signal, SNR_dB, 'measured');
    
    % 输出带噪声的回波信号
    echo_signal = echo_signal_noisy;
end
