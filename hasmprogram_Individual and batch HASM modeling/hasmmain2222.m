%   此程序为HASM模型的主程序，用于HASM插值
%
%   输入数据包括样点数据（可以txt格式或者excel格式）+迭代初值（Arcmap中的栅格数据转换成的ASCII格式），输出数据为栅格数据（Arcmap可以直接读入的ASCII格式）
%   需要用户根据自己的计算问题选择的参数为8个，即本程序中canshus=[]中的8个参数
%   用户需要设置好工作目录，将相关的输入数据放入数据目录中，计算结果也在数据目录中保存。
%   使用本代码的用户，请注意保护HASM模型的知识产权
%   HASM模型的介绍，请参考HASM模型原理与应用简介.doc文档
%   用户可以根据自己的研究目的需要，对HASM模型的相关函数进行改造
%   HASM模型本套代码基于MATLAB2016b编写，高版本的MATLAB环境下，本代码可以正常使用，但有的函数如shangxiajie，会有提示更换高版本的MATLAB自带函数
%   HASM模型使用过程中，如果遇到问题，可以联系yue@lreis.ac.cn或者duzp@lreis.ac.cn

clear all;
global wuchaid CGerror CGmaxtimes guimo caiyangid lamdazhi jizhiid lamdaid pinghuaid hasmtime hasmerror yuchuliid banjing songchi raodong luid;
CGerror=1e-9;  %%% PCG迭代误差终止参数
CGmaxtimes=5000;  %% PCG迭代最大迭代次数
guimo=20000000;  %%%% 根据计算规模，判断代数方程组是直接求解还是PCG迭代，该参数由用户根据自己的计算机计算能力来设置
lamdaid=0;%%% 各采样点权重，0表示所有采样点一样，1表示本采样点周边各点的方差，2表示本采样点与周围点均值的差，
hasmerror=1e-12;  %%% HASM 外迭代误差终止参数
yuchuliid=1; %%% PCG迭代时所采用预处理的方法 取1或者3
wuchaid=1; %%wuchaid取1表示计算RMSE；wuchaid取2表示计算平均绝对值误差；wuchaid取3表示计算平均误差；
raodong=0;%% 确定在有采样点的网格，其值在采样值上的扰动[0 1)

 %%%%以下为需要设置的参数，其中参数说明附有*********的几个参数对计算结果影响最大   
canshus=[2, 0.5, 2, 1, 50, 2, 15, 0];  
lamdazhi=canshus(1,1);%%% lamda 的值，大于0，一般不取太大(<50)**********
songchi=canshus(1,2);%% 松弛系数，决定某网格点上下界时，如何根据其邻点极值进行松弛决定,取值范围为0到1之间[0.1 0.2 0.3 0.4 0.5 1]*******
jizhiid=canshus(1,3);%%%极值ID确定总体极值应该如何放松取值为[1 2 3]
pinghuaid=canshus(1,4);%%%取1或者0，决定是否采用平滑措施***********
caiyangid=canshus(1,5);%%% 采样处理方式，取[1 3 5]之一，表示不同的截断阶数
hasmtime=canshus(1,6);%%% HASM迭代最大迭代数***********
banjing=canshus(1,7);%%%计算上下届时搜索的邻点数 一般不小于4，20以内***********
luid=canshus(1,8);%%是否用上下界控制，取值为0表示不用，取值为1表示用***********
if pinghuaid==1
    lamdaid=2;
end
if caiyangid==1
    yuchuliid=1;
end

clear; clc;

mulu = 'D:\hasm_lunwen\第二次实验260119\灌木\';  % 数据目录
mulu2 = 'D:\hasm_lunwen\第二次实验260119\out\';
files = dir(fullfile(mulu, '*.csv'));       % 找所有 csv 文件
log_file = fullfile(mulu, 'missing_files.txt');     % 记录缺失文件日志

% --- 【修改部分】设置起始索引 ---
target_name_start = '0'; %0

start_index = 1;

for idx = 1:length(files)
    [~, name, ~] = fileparts(files(idx).name);
    % 检查文件名是否达到目标起始编号
    % 注意：这里是按字符串比较，保证与 dir() 函数的排序一致
    if strcmp(name, target_name_start) || (str2double(name) > str2double(target_name_start) && str2double(name) > 0)
        start_index = idx;
        break; % 找到起始点后跳出查找循环
    end
end

if start_index == 1 && str2double(files(1).name) < str2double(target_name_start)
    disp(['警告：未找到文件组 ' target_name_start ' 或其之后的组，将从第一个文件开始运行。']);
end
% --- 【修改部分】结束 ---


% 如果日志已存.在，先清空
fid_log = fopen(log_file, 'w');
fprintf(fid_log, '【缺失文件组日志】\n\n');
fclose(fid_log);

% --- 【修改部分】主循环从 start_index 开始 ---
for i = start_index:length(files)
    [~, name, ~] = fileparts(files(i).name);
    fprintf('正在处理第 %d 个文件组：%s (文件索引：%d)\n', i - start_index + 1, name, i);

    % ---- 各文件路径 ----
    caiyangshuju = fullfile(mulu, [name '.csv']);      % 采样数据
    chuzhishuju  = fullfile(mulu, [name '.txt']);      % 迭代初值
    ym_file      = fullfile(mulu, [name ' - 副本.txt']);      % 掩膜数据
    shuchumulu   = fullfile(mulu2, [name '_hasm2.txt']);    % 输出文件

    % ---- 文件存在性检查（兼容旧 MATLAB）----
    missing = false;
    miss_msg = sprintf('文件组 %s 缺失项：', name);

    if exist(caiyangshuju, 'file') ~= 2
        warning('? 未找到采样数据: %s', caiyangshuju);
        miss_msg = [miss_msg, ' [CSV缺失]'];
        missing = true;
    end
    if exist(chuzhishuju, 'file') ~= 2
        warning('? 未找到迭代初值: %s', chuzhishuju);
        miss_msg = [miss_msg, ' [IDW缺失]'];
        missing = true;
    end
    if exist(ym_file, 'file') ~= 2
        warning('? 未找到掩膜数据: %s', ym_file);
        miss_msg = [miss_msg, ' [YM缺失]'];
        missing = true;
    end

    if missing
        % 把缺失文件组写入日志
        fid_log = fopen(log_file, 'a');
        fprintf(fid_log, '%s\n', miss_msg);
        fclose(fid_log);
        continue;  % 跳过本轮循环
    end

    % ---- 读取采样数据 ----
    [x0, y0, H, mx, my, h, caiyangs, tests, chazhi] = ...
        shujuxls(caiyangshuju, [], chuzhishuju);
    % 如果采样数据为 txt 格式，改成：
    % [x0, y0, H, mx, my, h, caiyangs, tests, chazhi] = ...
    %     shuju(caiyangshuju, [], chuzhishuju);

    caiyang = [caiyangs(:,1), caiyangs(:,2), caiyangs(:,3)];

    tic;
    % ----------------------------------------------------
    % 注意：这里是您程序出错的地方，文件组 317 可能会再次出错
    % ----------------------------------------------------
    jieguo = hasm(chazhi, caiyang, h); 
    toc;

    % ---- 掩膜处理 ----
    [X0, Y0, H, mx, my, exwgs] = shuju2(ym_file);
    jieguo(exwgs == -9999) = -9999;

    % ---- 输出结果 ----
    jieguoshuchu(jieguo, shuchumulu, mx, my, x0, y0, H);

    fprintf('? 已输出: %s\n\n', shuchumulu);
end

disp('? 全部文件批处理完成！');

% 结束后打印缺失情况
type(log_file);
