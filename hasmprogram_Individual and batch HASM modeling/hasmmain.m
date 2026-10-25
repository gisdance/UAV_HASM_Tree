%    此程序为HASM模型的主程序，用于HASM插值
%
%    输入数据包括样点数据（可以txt格式或者excel格式）+迭代初值（Arcmap中的栅格数据转换成的ASCII格式），输出数据为栅格数据（Arcmap可以直接读入的ASCII格式）
%    需要用户根据自己的计算问题选择的参数为8个，即本程序中canshus=[]中的8个参数
%    用户需要设置好工作目录，将相关的输入数据放入数据目录中，计算结果也在数据目录中保存。
%    使用本代码的用户，请注意保护HASM模型的知识产权
%    HASM模型的介绍，请参考HASM模型原理与应用简介.doc文档
%    用户可以根据自己的研究目的需要，对HASM模型的相关函数进行改造
%    HASM模型本套代码基于MATLAB2016b编写，高版本的MATLAB环境下，本代码可以正常使用，但有的函数如shangxiajie，会有提示更换高版本的MATLAB自带函数
%    HASM模型使用过程中，如果遇到问题，可以联系yue@lreis.ac.cn或者duzp@lreis.ac.cn

clear all;
global wuchaid CGerror CGmaxtimes guimo caiyangid lamdazhi jizhiid lamdaid pinghuaid hasmtime hasmerror yuchuliid banjing songchi raodong luid;
CGerror=1e-9;  %%% PCG迭代误差终止参数
CGmaxtimes=5000;  %% PCG迭代最大迭代次数
guimo=2000000;  %%%% 根据计算规模，判断代数方程组是直接求解还是PCG迭代，该参数由用户根据自己的计算机计算能力来设置
lamdaid=0;%%% 各采样点权重，0表示所有采样点一样，1表示本采样点周边各点的方差，2表示本采样点与周围点均值的差，
hasmerror=1e-12;  %%% HASM 外迭代误差终止参数
yuchuliid=1; %%% PCG迭代时所采用预处理的方法 取1或者3
wuchaid=1; %%wuchaid取1表示计算RMSE；wuchaid取2表示计算平均绝对值误差；wuchaid取3表示计算平均误差；
raodong=0;%% 确定在有采样点的网格，其值在采样值上的扰动[0 1)

 %%%%以下为需要设置的参数，其中参数说明附有*********的几个参数对计算结果影响最大   
canshus=[1 0.6 2 1 3 10 6 0]; 
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


%%%以下为需要设置的数据目录
mulu='D:\data\data3\';  %%数据目录
caiyangshuju=strcat(mulu,'316.csv');  %%%% 采样数据
testshuju=[];   %%%% 检验数据        
chuzhishuju=strcat(mulu,'idw3162.txt');  %%%% 迭代初值
shuchumulu=strcat(mulu,'exhasmidw13.txt');  %%%% 输出目录

[x0,y0,H,mx,my,h,caiyangs,tests,chazhi]=shujuxls(caiyangshuju,testshuju,chuzhishuju);%%%%如果采样数据为excel格式，用该程序
%[x0,y0,H,mx,my,h,caiyangs,test,chazhi]=shuju(caiyangshuju,testshuju,chuzhishuju);%%%%如果采样数据为txt格式，用该程序

caiyang=[caiyangs(:,1) caiyangs(:,2) caiyangs(:,3)];
%test=[tests(:,1) tests(:,2) tests(:,3)];

tic;
jieguo=hasm(chazhi,caiyang,h);
toc;
[X0,Y0,H,mx,my,exwgs]=shuju2(strcat(mulu,'idw3162.txt'));%%%输入模拟区域掩膜栅格数据
jieguo(find(exwgs==-9999))=-9999;
jieguoshuchu(jieguo,shuchumulu,mx,my,x0,y0,H); %%%输出计算结果

%wucha=wuchajianyan(jieguo,test,h); %%%%如果有检验数据，可以用该函数计算误差.
