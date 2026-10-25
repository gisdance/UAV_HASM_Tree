function [X0,Y0,H,mx,my,chazhi]=shuju2(chuzhishuju);%%%%只读取ARCGIS生成的TXT栅格文件
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

%sInfo=fgets(fid);  iPos=find(sInfo==' ');  iPos=max(iPos);
%NODATA_value=str2num(sInfo(iPos+1:length(sInfo)));

fclose(fid);
            
chazhi=dlmread(chuzhishuju,'',6,0);   
chazhi=flipdim(chazhi,1);
chazhi=chazhi';
[mx,my]=size(chazhi);
if sum(abs(chazhi(mx,:)))==0
    chazhi(mx,:)=[];
    [mx,my]=size(chazhi);
end

