function [l,u]=shangxiajie(caiyang,mx,my,h);%%%%得到各栅格点的上下界
global banjing songchi raodong minzhi maxzhi pinghuaid; %%banjing这里为最大搜索数
m=(mx-2)*(my-2);
x=caiyang(:,1);
y=caiyang(:,2);
z=caiyang(:,3);
cyminzhi=min(z);%%采样点中的极值
cymaxzhi=max(z);
if minzhi>cyminzhi
    disp('minzhi设置过大，程序自动调整为采样集中最小值！');
    minzhi=cyminzhi;
end
if maxzhi<cymaxzhi
    disp('maxzhi设置过小，程序自动调整为采样集中最大值！');
    mazhi=cymaxzhi;
end
if (minzhi<cyminzhi*(1-songchi))
    disp('songshi或许设置太大？');
elseif (maxzhi>cymaxzhi*(1+songchi))
    disp('songshi或许设置太大？');
end
if raodong>songchi
    raodong=songchi/10;
    disp('raodong可能设置过大，程序自动调整raodong为songchi的十分之一!');
end

xid=round2(x./h); %%% 距离采样点(x,y)最近的网格点在所有内点网格中的x序号
yid=round2(y./h); %%% 距离采样点(x,y)最近的网格点在所有内点网格中的y序号
caiyangxulie=(xid-1).*(my-2)+yid; %%%在所有内点中的排序
l=zeros(mx-2,my-2);
u=zeros(mx-2,my-2);



for i=1:(mx-2)
    for j=1:(my-2)
        xuhao=(i-1)*(my-2)+j;
        juli=(x-i*h).^2+(y-j*h).^2;
        [sortjuli,ID]=sort(juli); clear sortjuli;   
        clear sortjuli;
        if ismember(xuhao,caiyangxulie)==1 %%%本栅格内有采样点，则取离网格中心最近的那一个采样值
            kongzhi=raodong;
            newz1=z(ID(1));
            tt=ID(2:(banjing+1));
            newz2=z(tt);
            newz3=saixuan([newz2' newz1]');
            if pinghuaid==2
                newz3=saixuan(newz3);
            end
            if ismember(newz1,newz3)==1
                newz=newz1;
            else  %%若离网格中心最近的点的值为奇异，则取周围点来计算上下界
                for k=4:banjing
                    va(k-3)=var(newz2(1:k));
                end
                [minva,idk]=min(va);clear minva;
                sousuobanjing=idk+3;
                tt=ID(2:sousuobanjing);
                newz=z(tt);
                if pinghuaid>=1
                    newz=saixuan(newz);%%%删除一个对方差影响最大的值
                    if pinghuaid==2
                        newz=saixuan(newz);%%%再删1个
                    end
                end
                clear tt;        
             end
        else%%%本栅格内没有采样点，则取离这个栅格中心最近的sousuobanjing个采样点
            kongzhi=songchi;
            tt=ID(1:banjing);
            newz=z(tt);
            clear tt;
            for k=4:banjing
                va(k-3)=var(newz(1:k));
            end
            [minva,idk]=min(va); clear minva;
            sousuobanjing=idk+3;
            tt=ID(1:sousuobanjing);
            newz=z(tt);
            if pinghuaid>=1
                newz=saixuan(newz);%%%删除一个对方差影响最大的值
                if pinghuaid==2
                    newz=saixuan(newz);
                end
            end
            clear tt;        
        end
        minz=min(newz);
        maxz=max(newz);
        if minz<0
            minzzz=minz*(1+kongzhi);
        else
            minzzz=minz*(1-kongzhi);
        end
        if maxz<0
            maxzzz=maxz*(1-kongzhi);
        else
            maxzzz=maxz*(1+kongzhi);
        end
        u(i,j)=min(maxzhi,maxzzz);
        l(i,j)=max(minzhi,minzzz);

        clear ID tt newz;
    end
end

pinghuachidu=20; %%%%这个参数，可以自行根据研究的数据进行调整

if pinghuaid==1
    l=(smoothts(l,'b',round(min(my/pinghuachidu,mx/pinghuachidu)))+(smoothts(l','b',round(min(my/pinghuachidu,mx/pinghuachidu))))')/2;%%%适用于MATLAB2016b版本
    u=(smoothts(u,'b',round(min(my/pinghuachidu,mx/pinghuachidu)))+(smoothts(u','b',round(min(my/pinghuachidu,mx/pinghuachidu))))')/2;%%%适用于MATLAB2016b版本
%    l=(smoothdata(l,'movmean',round(min(my/pinghuachidu,mx/pinghuachidu)))+(smoothdata(l','movmean',round(min(my/pinghuachidu,mx/pinghuachidu))))')/2;%%%%如果MATLAB版本是2018以后的版本，改用此行
%    u=(smoothdata(u,'movmean',round(min(my/pinghuachidu,mx/pinghuachidu)))+(smoothdata(u','movmean',round(min(my/pinghuachidu,mx/pinghuachidu))))')/2;%%%%如果MATLAB版本是2018以后的版本，改用此行
end

function b=round2(x)
%%%%%%%最接近的整数，如果跟两个整数距离相等，则取小的那个
a=abs(x-round(x));
if a==0.5
    b=round(x)-1;
else
    b=round(x);
end

function newz=saixuan(z); %%%把对一系列样点中，方差影响最大的点删除
fangcha=var(z);%%%所有点的方差
for i=1:length(z)
    newz=z;
    newz(i)=[];
    newf(i)=abs(var(newz)-fangcha); %%%%该样点删了以后余下点的方差，与全部样点的方差的对比
end
[nf,id]=max(newf); clear nf;
if length(id)==length(newf)
    newz=z;
else
    z(id)=[];
    newz=z;
end