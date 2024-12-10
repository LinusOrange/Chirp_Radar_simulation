function chirp_signal = generate_chirp_signal(f0, B, T, A, t)
    % 生成线性调频（Chirp）信号
    % 输入：
    % f0 - 发射信号的起始频率 (Hz)
    % B  - 信号的带宽 (Hz)
    % T  - 信号持续时间 (秒)
    % A  - 信号的幅度
    % t  - 时间向量 (秒)
    %
    % 输出：
    % chirp_signal - 生成的Chirp信号

    chirp_signal = A * cos(2 * pi * f0 * t + pi * (B / T) * t.^2);
end
