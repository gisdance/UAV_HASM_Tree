function wucha=wuchajianyan(jieguo,test,h); %%%有检验数据时，用于计算模拟误差
global wuchaid;
%%% id=[id expfloor];
[mx,my]=size(jieguo);%%%%%minx,miny,maxx,maxy都应该是jieguo的坐标的极值
[hang,lie]=size(test);
if (mx==hang)&(my==lie)  %%%%说明检验数据是整个研究区域的栅格数据
	if wuchaid==1
            wucha=sqrt(sum(sum((jieguo-test).^2))/(mx*my));  %%%%均方根误差
    elseif wuchaid==2
            wucha=(sum(sum(abs(jieguo-test)))/(mx*my));  %%%平均绝对值误差
    elseif wuchaid==3
            wucha=(sum(sum((jieguo-test)))/(mx*my));  %%%平均误差
    end

else  %%%%说明检验数据是样点数据,此时用检验样点所在栅格处的栅格值作为模拟值与样点值计算误差
    temp=0;
    x2=round2(test(:,1)/h)+1;%%%%%%%%%用所在图斑的值
    y2=round2(test(:,2)/h)+1;
    for i=1:hang
            temp=jieguo(x2(i),y2(i));
            wuchas(i)=(temp-test(i,3));
    end
    if wuchaid==1
        wucha=sqrt(sum(wuchas.^2)/hang);  %%%%均方根误差
    elseif wuchaid==2
        wucha=sum(abs(wuchas))/hang; %%%平均绝对值误差
    elseif wuchaid==3
        wucha=sum(wuchas)/hang;  %%%平均误差
    end
end