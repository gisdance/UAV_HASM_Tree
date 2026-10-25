function [X0,Y0,H,mx,my,h,caiyang,test,chazhi]=shuju(caiyangshuju,testshuju,chuzhishuju);%%%%读取ARCGIS倒出来的TXT栅格文件和TXT格式的采样数据
sFilename=chuzhishuju;
fid=fopen(sFilename,'r');

sInfo=fgets(fid);  iPos=find(sInfo==' ');  iPos=max(iPos);
mx=str2num(sInfo(iPos+1:length(sInfo)));

sInfo=fgets(fid);  iPos=find(sInfo==' ');  iPos=max(iPos);
my=str2num(sInfo(iPos+1:length(sInfo)));

sInfo=fgets(fid);  iPos=find(sInfo==' ');  iPos=max(iPos);
X0=str2num(sInfo(iPos+1:length(sInfo)));

sInfo=fgets(fid);  iPos=find(sInfo==' ');  iPos=max(iPos);
Y0=str2num(sInfo(iPos+1:length(sInfo)));

sInfo=fgets(fid); iPos=find(sInfo==' ');  iPos=max(iPos);
H=str2num(sInfo(iPos+1:length(sInfo)));
%%%以上是读取ARCGIS栅格数据的头文件
%sInfo=fgets(fid);  iPos=find(sInfo==' ');  iPos=max(iPos);
%NODATA_value=str2num(sInfo(iPos+1:length(sInfo)));
fclose(fid);
Lx=1;
h=Lx/(mx-1);
Ly=(my-1)*h;%%%模拟区域归一化
if length(caiyangshuju)>0
    caiyang=dlmread(caiyangshuju,'',1,0);
    XX=X0+H/2;
    YY=Y0+H/2;
    caiyang(:,1)=(caiyang(:,1)-XX)/((mx-1)*H);
    caiyang(:,2)=(caiyang(:,2)-YY)/((mx-1)*H);
    caiyang(caiyang(:,1)<(0.5*h),:)=[];
    caiyang(caiyang(:,1)>((mx-2)*h+0.5*h),:)=[];
    caiyang(caiyang(:,2)<(0.5*h),:)=[];
    caiyang(caiyang(:,2)>((my-2)*h+0.5*h),:)=[]; %%%把超出范围的采样点去掉
    x=caiyang(:,1);
    y=caiyang(:,2);
%    [ss,id]=unique(x.^2+y.^2);
%    caiyang=caiyang(id,:);
    clear ss id x y z;
end            


if length(testshuju)>0
    test=dlmread(testshuju,'',1,0);
    test(:,1)=(test(:,1)-XX)/((mx-1)*H);
    test(:,2)=(test(:,2)-YY)/((mx-1)*H);
else
    test=[];
end

chazhi=dlmread(chuzhishuju,'',6,0);   
chazhi=flipdim(chazhi,1);
chazhi=chazhi';%%%把0点从左下，转成左上
[mx,my]=size(chazhi);
if sum(abs(chazhi(mx,:)))==0  %%%有时候，ARCGIS倒出来的TXT栅格文件，最后一列会是空格
    chazhi(mx,:)=[];
    [mx,my]=size(chazhi);
end
