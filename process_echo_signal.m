function [estimated_range, estimated_velocity] = process_echo_signal(chirp_signal, echo_signal, f0, B, T, c, Fs)
    % 处理回波信号，提取目标的距离和速度
    % 输入：
    % chirp_signal   - 发射的Chirp信号（向量）
    % echo_signal    - 接收的回波信号（向量）
    % f0             - 发射信号的起始频率 (Hz)
    % B              - 信号的带宽 (Hz)
    % T              - 信号持续时间 (秒)
    % c              - 光速 (m/s)
    % Fs             - 采样率 (Hz)
    %
    % 输出：
    % estimated_range    - 估算的目标距离 (米)
    % estimated_velocity - 估算的目标速度 (米/秒)

    % 1. 匹配滤波进行测距
    [corr, lags] = xcorr(echo_signal, chirp_signal);
    [~, max_idx] = max(abs(corr));
    time_delay = lags(max_idx) / Fs;
    estimated_range = (c * time_delay) / 2;

    % 2. 多普勒频移估计进行测速
    % 解调回波信号：与发射信号相乘（匹配滤波的一部分）
    dechirped_signal = echo_signal .* conj(chirp_signal);
    
    % 使用Hanning窗减少频谱泄漏
    window = hann(length(dechirped_signal))';
    dechirped_signal_windowed = dechirped_signal .* window;
    
    % 执行高分辨率FFT（零填充以增加频谱分辨率）
    N = 2^nextpow2(length(dechirped_signal_windowed) * 4);  % 4倍零填充
    Y = fft(dechirped_signal_windowed, N);
    Y = fftshift(Y);                    % 将零频率移到中心
    freq_axis = (-N/2:N/2-1)*(Fs/N);    % 频率轴
    
    % 找到FFT幅度最大的频率分量
    [~, peak_doppler_idx] = max(abs(Y));
    % 线性插值法提高峰值频率估计精度
    if peak_doppler_idx > 1 && peak_doppler_idx < N
        alpha = abs(Y(peak_doppler_idx - 1));
        beta = abs(Y(peak_doppler_idx));
        gamma = abs(Y(peak_doppler_idx + 1));
        p = 0.5 * (alpha - gamma) / (alpha - 2*beta + gamma);
        doppler_freq = freq_axis(peak_doppler_idx) + p * (Fs/N);
    else
        doppler_freq = freq_axis(peak_doppler_idx);
    end

    % 计算多普勒频移对应的速度
    lambda = c / (f0 + B/2);            % 使用中心频率
    estimated_velocity = doppler_freq * lambda / 2;  % v = f_d * lambda / 2
end
