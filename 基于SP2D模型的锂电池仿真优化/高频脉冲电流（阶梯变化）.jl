using Plots, CSV, DataFrames, Interpolations, Statistics, StatsBase
include("../src/JuBat.jl") 

# 设置电池参数
param_dim = JuBat.ChooseCell("LG M50")
param_dim.cell.v_h = 4.3

# 参数设置
total_time = 1000      # 总时长(秒)
time_step = 0.001     # 更小步长(毫秒级)以捕捉ns瞬态
time = collect(0:time_step:total_time)

# 多级脉冲参数
pulse_interval = 12   # 每12秒一个脉冲
pulse_width = 0.05      # 脉冲持续时间5ms
I_base = 5          # 基准电流(1C=5A)

current = zeros(length(time))
for i in eachindex(time)
    t = time[i]
    
    # 判断是否在脉冲区间内
    if mod(t, pulse_interval) < pulse_width
        # 三级阶梯划分
        phase = mod(t, pulse_width) / pulse_width  # 脉冲内相对位置[0,1)
        
        if phase < 0.3
            # 第一级：0.5C上升沿
            current[i] = 0.5 * I_base * (1 + 0.2*sin(2π*1000*t))  # 叠加1kHz调制
        elseif phase < 0.6
            # 第二级：2C平台
            current[i] = 2.0 * I_base * (1 + 0.1*sin(2π*5000*t))  # 叠加5kHz调制
        else
            # 第三级：4C下降沿
            current[i] = 4.0 * I_base * exp(-(phase-0.6)^2/0.01)   # 高斯衰减
        end
        
        # 添加ns级开关瞬态（位置随机）
        if rand() < 0.01 && phase > 0.2 && phase < 0.8
            current[i] += 0.8 * exp(-(mod(t,1e-6)/1e-9)^2)  # 10ns级尖峰
        end
    else
        # 脉冲间隔期：维持0.1C背景电流
        current[i] = 0.1 * I_base
    end
    
    # 添加宽频噪声（保留原有特征）
    current[i] += 0.05 * I_base * randn()
end

# 创建电流插值函数
itp = linear_interpolation(time, current, extrapolation_bc=Flat())


# 设置模拟选项
opt = JuBat.Option()
opt.mechanicalmodel = "full"
opt.model = "P2D"  # 使用P2D模型
opt.time = time  # 使用与电流数据相同的时间步长

# 设置电流函数
opt.Current = t -> itp(t)  # 正确用法

# 创建和运行P2D模型模拟
println("开始模拟高频脉冲电流工况... P2D模型")
case = JuBat.SetCase(param_dim, opt)
result = JuBat.Solve(case)
println("P2D模型模拟完成")

# 测量P2D模型计算时间
p2d_time = @elapsed begin
    case = JuBat.SetCase(param_dim, opt)
    result = JuBat.Solve(case)
end
println("P2D模型计算时间: ", p2d_time, " 秒")

# 提取P2D模型结果数据
time_result = result["time [s]"]
voltage_p2d = result["cell voltage [V]"]
concentration_p2d = result["negative particle surface lithium concentration [mol/m^3]"]
stress_p2d = result["negative particle surface tangential stress[Pa]"]

# 处理P2D模型结果的维度
if ndims(concentration_p2d) > 1
    concentration_p2d = concentration_p2d[1, :]
end

if ndims(stress_p2d) > 1
    stress_p2d = stress_p2d[1, :]
end

# 设置sP2D模型
opt.model = "sP2D"  # 使用sP2D模型
println("开始模拟高频脉冲电流工况... sP2D模型")
case_sP2D = JuBat.SetCase(param_dim, opt)
result_sP2D = JuBat.Solve(case_sP2D)
println("sP2D模型模拟完成")

# 测量sP2D模型计算时间
sp2d_time = @elapsed begin
    case_sP2D = JuBat.SetCase(param_dim, opt)
    result_sP2D = JuBat.Solve(case_sP2D)
end
println("P2D模型计算时间: ", p2d_time, " 秒")
println("sP2D模型计算时间: ", sp2d_time, " 秒")

# 提取sP2D模型结果数据
voltage_sP2D = result_sP2D["cell voltage [V]"]
concentration_sP2D = result_sP2D["negative particle surface lithium concentration [mol/m^3]"]
stress_sP2D = result_sP2D["negative particle surface tangential stress[Pa]"]

# 处理sP2D模型结果的维度
if ndims(concentration_sP2D) > 1
    concentration_sP2D = concentration_sP2D[1, :]
end

if ndims(stress_sP2D) > 1
    stress_sP2D = stress_sP2D[1, :]
end

# 创建电压图，包括P2D和sP2D的结果
p1 = plot(time_result, voltage_p2d, 
    label="voltage (P2D)", 
    xlabel="time [s]", 
    ylabel="voltage [V]", 
    lw=2, color=:blue)

plot!(time_result, voltage_sP2D, 
    label="voltage (sP2D)", 
    title="voltage_comparison (P2D vs sP2D)",
    linestyle=:dash, color=:red)

# 创建浓度图，包括P2D和sP2D的结果
p2 = plot(time_result, concentration_p2d, 
    label="concentration (P2D)", 
    xlabel="time [s]", 
    ylabel="concentration [mol/m³]", 
    lw=2, color=:blue)

plot!(time_result, concentration_sP2D, 
    label="concentration (sP2D)", 
    title="concentration_comparison (P2D vs sP2D)",
    linestyle=:dash, color=:fuchsia)

# 创建应力图，包括P2D和sP2D的结果
p3 = plot(time_result, stress_p2d, 
    label="stress (P2D)", 
    xlabel="time [s]", 
    title="stress_comparison (P2D vs sP2D)",
    lw=2, color=:blue)

plot!(time_result, stress_sP2D, 
    label="stress (sP2D)", 
    ylabel="stress [Pa]", 
    linestyle=:dash, color=:darkorange)

# 创建电流图
p4 = plot(time, current, 
    label="Current", 
    xlabel="time [s]", 
    ylabel="Current [A]", 
    title="Pulse Waveform Current Profile",
    lw=2, size=(1600, 400), color=:orange)

# 组合图表
plot_combined = plot(p1, p2, p3, p4, 
layout=(4, 1), 
size=(800, 800))

# 保存图表
savefig(p1, "pulse_voltage_comparison.pdf")
savefig(p2, "pulse_concentration_comparison.pdf")
savefig(p3, "pulse_stress_comparison.pdf")
savefig(p4, "pulse_current_profile.pdf")

savefig(plot_combined, "pulse_battery_analysis_comparison_super.pdf")

# 计算绝对值差
voltage_error = abs.((voltage_sP2D) .- (voltage_p2d))
concentration_error = abs.((concentration_sP2D) .- (concentration_p2d))
stress_error = abs.((stress_sP2D) .- (stress_p2d))

# 计算误差百分比
voltage_error_percentage = (voltage_error ./ voltage_p2d) .* 100
concentration_error_percentage = (concentration_error ./ concentration_p2d) .* 100
stress_error_percentage = (stress_error ./ stress_p2d) .* 100

# 获取最大误差
max_voltage_error = maximum(voltage_error)
max_concentration_error = maximum(concentration_error)
max_stress_error = maximum(stress_error)

# 获取最大误差百分比
max_voltage_error_percentage = maximum(voltage_error_percentage)
max_concentration_error_percentage = maximum(concentration_error_percentage)
max_stress_error_percentage = maximum(stress_error_percentage)

max_current = maximum(current)

# 计算平均绝对误差
mean_voltage_error = mean(abs.(voltage_error))
mean_concentration_error = mean(abs.(concentration_error))
mean_stress_error = mean(abs.(stress_error))

# 计算平均误差百分比（排除除以零的情况）
function safe_mean_percentage(errors, references)
    valid_indices = findall(x -> x != 0, references)
    isempty(valid_indices) ? 0.0 : mean(abs.(errors[valid_indices] ./ references[valid_indices])) * 100
end

mean_voltage_error_percentage = safe_mean_percentage(voltage_error, voltage_p2d)
mean_concentration_error_percentage = safe_mean_percentage(concentration_error, concentration_p2d)
mean_stress_error_percentage = safe_mean_percentage(stress_error, stress_p2d)

# 确保所有数组长度一致
min_length = min(length(time_result), length(voltage_error_percentage), 
                length(concentration_error_percentage), length(stress_error_percentage))
time_plot = time_result[1:min_length]
voltage_error_plot = voltage_error_percentage[1:min_length]
concentration_error_plot = concentration_error_percentage[1:min_length]
stress_error_plot = stress_error_percentage[1:min_length]

# 创建误差百分比变化图
p5 = plot(time_plot, voltage_error_plot, 
    label="Voltage Error (%)", 
    xlabel="Time [s]", 
    ylabel="Error Percentage (%)",
    title="Model Error Comparison (P2D vs sP2D)",
    lw=2, color=:green, ylims=(-15, 15))  # 调整坐标范围

plot!(time_plot, concentration_error_plot, 
    label="Concentration Error (%)", 
    lw=2, color=:blue)

# 添加应力误差散点（仅有效点）
scatter!(time_plot, stress_error_plot, 
    label="Stress Error (%)", 
    markershape=:diamond, markercolor=:red, 
    markersize=2)

savefig(p5, "pulse_battery_error_percentage_comparison.pdf")

# 打印最大误差和最大误差百分比
println("最大电压误差: $max_voltage_error V")
println("平均电压误差: $mean_voltage_error V")
println("最大电压误差百分比: $max_voltage_error_percentage %")
println("平均电压误差百分比: $mean_voltage_error_percentage %")
println("最大浓度误差: $max_concentration_error mol/m³")
println("平均浓度误差: $mean_concentration_error mol/m³")
println("最大浓度误差百分比: $max_concentration_error_percentage %")
println("平均浓度误差百分比: $mean_concentration_error_percentage %")
println("最大应力误差: $max_stress_error Pa")
println("平均应力误差: $mean_stress_error Pa")
println("最大应力误差百分比: $max_stress_error_percentage %")
println("平均应力误差百分比: $mean_stress_error_percentage %")

# 保存数据到CSV
results_df = DataFrame(
    "Time (s)" => time,
    "Voltage (P2D) (V)" => voltage_p2d,
    "Voltage (sP2D) (V)" => voltage_sP2D,
    "Voltage Error (V)" => voltage_error,
    "average Voltage Error (V)" => mean_voltage_error,
    "Voltage Error Percentage (%)" => voltage_error_percentage,
    "average Voltage Error Percentage (%)" => mean_voltage_error_percentage,
    "Concentration (P2D) (mol/m³)" => concentration_p2d,
    "Concentration (sP2D) (mol/m³)" => concentration_sP2D,
    "Concentration Error (mol/m³)" => concentration_error,
    "average Concentration Error (mol/m³)" => mean_concentration_error,
    "Concentration Error Percentage (%)" => concentration_error_percentage,
    "average Concentration Error Percentage (%)" => mean_concentration_error_percentage,
    "Stress (P2D) (Pa)" => stress_p2d,
    "Stress (sP2D) (Pa)" => stress_sP2D,
    "Stress Error (Pa)" => stress_error,
    "average Stress Error (Pa)" => mean_stress_error,
    "Stress Error Percentage (%)" => stress_error_percentage,
    "average Stress Error Percentage (%)" => mean_stress_error_percentage,
    "Current (A)" => [itp(t) for t in time]
)

CSV.write("pulse_battery_results_comparison.csv", results_df)

println("分析完成，结果已保存")

# 引用信息
JuBat.Citation()