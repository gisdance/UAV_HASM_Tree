function jieguo=hasm(chazhi,caiyang,h);%%%%hasm计算函数
global caiyangid guimo hasmtime yuchuliid luid maxzhi minzhi jizhiid;
%%%%  固定迭代次数，无误差检验的HASM迭代程序
minzzz=min(caiyang(:,3));
maxzzz=max(caiyang(:,3));
if jizhiid==1
    minzhi=minzzz;
    maxzhi=maxzzz;
elseif jizhiid==2
    if minzzz<0
        minzhi=1.1*minzzz;
    else
        minzhi=0.9*minzzz;
    end
    if maxzzz<0
        maxzhi=0.9*maxzzz;
    else
        maxzhi=1.1*maxzzz;
    end
else
    if minzzz<0
        minzhi=1.2*minzzz;
    else
        minzhi=0.8*minzzz;
    end
    if maxzzz<0
        maxzhi=0.8*maxzzz;
    else
        maxzhi=1.2*maxzzz;
    end
end

%%%%以上是对模拟结果的最大最小值进行控制
clear maxzzz minzzz;
[mx,my]=size(chazhi);
if isempty(caiyang(:,1))
    disp('区域内没有采样点，请检查程序和数据是否有错！');
    jieguo=chazhi;
else
    lamda=lisangdu(caiyang(:,1),caiyang(:,2),caiyang(:,3));%%%%计算lambda向量
    if ismember(caiyangid,[1 3 5])==0
        disp('caiyangid赋值错误(只能是1、3或者5)，程序自动改成3');
        caiyangid=3;
    end
    [GG,GH]=taylorcaiyang(caiyang(:,1),caiyang(:,2),caiyang(:,3),chazhi,lamda,h);%%%%计算采样向量和采样矩阵，生成lambda^2*G'G,lambda^2*G'*H
   
    if (mx*my)<guimo  %%%规模小，用直接解法
        xishus=taylorxishu(mx,my,GG);%%%%系数矩阵A'*A+B'*B+lambda^2*G'G
        clear GG;
        if luid==1  %%%是否用上下界控制？
            [l,u]=shangxiajie(caiyang,mx,my,h);%%%%生成上下界
        end
         clear caiyang grid;
        for is=1:hasmtime
            b=quyumoni(chazhi,h)+GH;  %%%%右端项A'*c+B'*d+lambda^2*G'*H
            xx=xishus\b;
            clear b;
            chazhi(2:(mx-1),2:(my-1))=(reshape(xx,(my-2),(mx-2)))';%%%%把一维向量，转成二维矩阵
            clear xx;
            if luid==1  %%%%进行不等式检验
                for i=1:(mx-2)
                    for j=1:(my-2)
                        if chazhi(i+1,j+1)<l(i,j)
                            chazhi(i+1,j+1)=l(i,j);
                        elseif chazhi(i+1,j+1)>u(i,j)
                            chazhi(i+1,j+1)=u(i,j);
                        end
                    end
                end
            end
        end
    else %%%规模大，用PCG解法
        M=duijiaoxian(mx,my); %%% A'A+B'B的主对角线
        yuxishu=yuchulixishu(mx,my,GG,M,yuchuliid); %%%%生成A'*A+B'*B+lambda^2*G'G的预处理矩阵
        if luid==1
            [l,u]=shangxiajie(caiyang,mx,my,h); %%%生成上下界
        end
        clear caiyang grid;
        for t=1:hasmtime
            b=quyumoni(chazhi,h)+GH;   %%%%右端项A'*c+B'*d+lambda^2*G'*H
            xx=reshape((chazhi(2:(mx-1),2:(my-1)))',(mx-2)*(my-2),1);
            xx=tayloryuchuliCG(mx,my,b,xx,yuxishu,GG,M);  %%%%用PCG迭代来进行计算
            clear b;
            chazhi(2:(mx-1),2:(my-1))=(reshape(xx,(my-2),(mx-2)))';
            if luid==1  %%%进行不等式检验
                for i=1:(mx-2)
                    for j=1:(my-2)
                        if chazhi(i+1,j+1)<l(i,j)
                            chazhi(i+1,j+1)=l(i,j);
                        elseif chazhi(i+1,j+1)>u(i,j)
                            chazhi(i+1,j+1)=u(i,j);
                        end
                    end
                end
            end
            clear xx;
        end
    end 
    jieguo=chazhi;
    clear chazhi;
end

function jieguo=taylorxishu(mx,my,GG); %%%%生成全系数矩阵，可以直接求逆，本矩阵为A'A＋B'B +lambda^2*G'G ******
n=(mx-2)*(my-2);
e=ones(n,1);
pxia=e;
pshang=e;
mx=mx-2;
my=my-2;
pxia(my:my:(n-my))=0;
pshang((my+1):my:(n-my+1))=0;
xishu1=spdiags([pxia -2*e pshang],-1:1,n,n);%%% X方向方程的系数矩阵A
xishu2=spdiags([e -2*e e],[-my 0 my],n,n);%%% Y方向方程的系数矩阵B
clear pxia pshang e;
jieguo=xishu1'*xishu1+xishu2'*xishu2+GG;
clear xishu1 xishu2;

function M=duijiaoxian(mx,my); 
m=(mx-2)*(my-2);
M=12*ones(m,1);
M(1:(my-2):(m+3-my))=11;
M((my-2):(my-2):m)=11;
M(1:(my-2))=M(1:(my-2))-1;
M((m-my+3):m)=M((m-my+3):m)-1;

function x=tayloryuchuliCG(mx,my,b,x0,yuxishu,GG,M);   %%%%%对角线预处理CG迭代方法 yuxishu 为三对角预处理阵，而不是原方程系数矩阵
global CGerror CGmaxtimes;
m=(mx-2)*(my-2);
mob=sqrt(sum(b.^2)/m);%%% b的模
r=b-AP(GG,x0,mx,my,M);
clear b;
%newr=r;
ruo=sum(r.^2)/m;
x=x0;
clear x0;
k=0;
if  min(size(yuxishu))==1
    z=r./yuxishu;
else
    z=yuxishu\r;
end

while ((sqrt(ruo)>(CGerror*mob))&(k<CGmaxtimes))
    %newz=newr./M; 
    k=k+1;
    if k==1
        p=z;
    else
        beita=newrz/rz;
        p=z+beita*p;
    end
    rz=r'*z; 
    w=AP(GG,p,mx,my,M);
    alfa=rz/(p'*w);  %    w=AP(M,p,mx,my,lamda);
    x=x+alfa*p;
    r=r-alfa*w;
    if  min(size(yuxishu))==1
        z=r./yuxishu;
    else
        z=yuxishu\r;
    end
    newrz=r'*z;
    ruo=sum(r.^2)/m;
end %%%%%迭代过程中需要存储 r z x p w 5个矩阵 做6*m次乘法
clear r p z w yuxishu;

function pp=AP(GG,p,mx,my,M); %%计算矩阵与向量的乘法：A*p
pp=zeros((mx-2)*(my-2),1);
pp=xiangliangweiyi2(p,mx,my,2)+xiangliangweiyi2(p,mx,my,-2)-4*xiangliangweiyi2(p,mx,my,1)-4*xiangliangweiyi2(p,mx,my,-1);
pp=pp-4*xiangliangweiyi1(p,my-2)+xiangliangweiyi1(p,2*(my-2))-4*xiangliangweiyi1(p,-(my-2))+xiangliangweiyi1(p,-2*(my-2));
pp=pp+GG*p+M.*p;

function temp=xiangliangweiyi1(p,a);
m=max(size(p));
temp=zeros(m,1);
if a>=0
    temp(1:(m-a))=p((a+1):m); %%%%对角线上方
elseif a<0
    temp((-a+1):m)=p(1:(m+a)); %%%%对角线下方
end

function temp=xiangliangweiyi2(p,mx,my,a);
m=(mx-2)*(my-2);
temp=zeros(m,1);
if a==1
    p(1:(my-2):(m-my+3))=0;
elseif a==2
    p((my-1):(my-2):(m-my+3))=0;
    p(my:(my-2):(m-my+4))=0;
elseif a==(-1)
    p((my-2):(my-2):(m-my+2))=0;
elseif a==(-2)
    p((my-2):(my-2):m)=0;
    p((my-3):(my-2):(m-1))=0;
end
temp=xiangliangweiyi1(p,a);

function yuxishu=yuchulixishu(mx,my,GG,M,yuchuliid); %%%%生成三对角阵，作为预处理子，本矩阵为A'A＋B'B+lambda^2*G'G 的中间三对角 ******

if yuchuliid==1
    n=(mx-2)*(my-2);
    yuxishu=zeros(n,1);
    for i=1:n
        yuxishu(i)=M(i)+GG(i,i);
    end
else
    n=(mx-2)*(my-2);
    e=ones(n,1);
    pxia=e;
    pshang=e;
    clear e;
    mx=mx-2;
    my=my-2;
    pxia(my:my:(n-my))=0;
    pshang((my+1):my:(n-my+1))=0;
    yuxishu=spdiags([-4*pxia M -4*pshang],-1:1,n,n);
    GG=GG+yuxishu;
    clear yuxishu;
    ss=[0 (diag(GG,1))']';
    sx=[(diag(GG,-1))' 0]';
    yuxishu=spdiags([sx diag(GG) ss],-1:1,n,n); %%%% A'A+B'B+GG的三对角，作为预处理子
    clear ss sx;
end

