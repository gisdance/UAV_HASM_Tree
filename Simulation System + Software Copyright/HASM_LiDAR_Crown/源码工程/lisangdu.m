function lisangzhi=lisangdu(x,y,z);%%%%根据delaunay泰森三角计算每个点邻域内点的离散值
%%%% lamdaid=0 表示所有采样点权重一样
global lamdazhi lamdaid;
R=min(15,length(x)/2);  %%% R的值，用户可以自行设定，但需要保证不小于4
m=length(x);
if lamdaid==0
    lisangzhi=lamdazhi*ones(m,1);
elseif lamdaid==1%%%根据本样点及其联系的样点的方差来决定本点的权重 
    tri=delaunay(x,y);
    for i=1:m
        tt1=find(tri(:,1)==i);
        tt2=find(tri(:,2)==i);
        tt3=find(tri(:,3)==i);
        dd=union(union(tt1,tt2),tt3);  %%%所有含有 i 的三角形tri的行号
        ddi=union(union(tri(dd,1),tri(dd,2)),tri(dd,3));   %%%% 含 i 的tri 各行所有元素
        ddi=setdiff(ddi,i);  %%%去掉其中重复的
        lisangzhi(i)=var(z(ddi)); %%%%方差
        clear dd ddi;
    end
    lisangzhi=lisangzhi'; %%%%%  输出的是列向量
    maxzhi=max(lisangzhi);
    minzhi=min(lisangzhi);
    if maxzhi==minzhi
        lisangzhi=lamdazhi*ones(length(lisangzhi),1);
    else
        %lisangzhi=(lisangzhi*(99/(maxzhi-minzhi))+(maxzhi-100*minzhi)/(maxzhi-minzhi))*lamda/100;
        lisangzhi=(-lisangzhi*(99/(maxzhi-minzhi))+(100*maxzhi-minzhi)/(maxzhi-minzhi))*lamdazhi/100;%%%%方差最大的为0.01，方差最小的为1
    end
elseif lamdaid==2%%根据本样点及其周围邻点均值的差来决定本点的权重，目的是除去某些异常点的影响
    for i=1:m
        juli=(x-x(i)).^2+(y-y(i)).^2;
        [sortjuli,ID]=sort(juli);    %%%距离排序
        newz=z(ID(2:R));
        cha(i)=abs(z(i)-mean(newz));
        clear newz juli sortjuli ID;
    end
    maxzhi=max(cha);
    minzhi=min(cha);
    if maxzhi==minzhi
        lisangzhi=lamdazhi*ones(length(x),1);
    else
        lisangzhi=lamdazhi*(maxzhi-0.00001*minzhi-cha*0.99999)/(maxzhi-minzhi);%%%%差值最大的，为0.00001，差值小的为1
    end
end