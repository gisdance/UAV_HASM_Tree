function ABDE=quyumoni(chazhi,h);  
%%% 计算右端项 A'*d+B'*e ，采用分区域计算的方法
maxkuai=1000;
[mx my]=size(chazhi);
m=(mx-2)*(my-2);
chongdie=6;
zzsx=fenchai(mx,maxkuai);%%%%%%%%%%%  x方向的子区域数
zzsy=fenchai(my,maxkuai);%%%%%%%%%%%  y方向的子区域数
D=zeros(mx,my);
E=zeros(mx,my);
mins=min(zzsx,zzsy);
maxs=max(zzsx,zzsy);
for i=1:mins
    for j=1:maxs
        [jisuanminx,jisuanmaxx,jisuanminy,jisuanmaxy,fenkuaiminx,fenkuaimaxx,fenkuaiminy,fenkuaimaxy]=fcjz(i,j,mx,my,chongdie,maxkuai);
        jieguo=chazhi(jisuanminx:jisuanmaxx,jisuanminy:jisuanmaxy);
        [fenmx,fenmy]=size(jieguo);
 %       tr=gradient(jieguo)/h; %%% tr
 %       te=(gradient(jieguo'))'/h;  %%%% te
 %       te2=gradient2(jieguo)/(h*h);
 %       tr2=(gradient2(jieguo'))'/(h*h);
 %       functionF=te.*tr;
 %       functionE=1+te.*te;
 %       functionG=1+tr.*tr;
 %       functionEG=(functionE+functionG-1);
%        functionL=hx*hx*te2./functionEG;
%        functionN=hy*hy*tr2./functionEG;
%        clear te2 tr2 ;
 %       tex=(gradient(functionE'))'/h;
 %       tfx=(gradient(functionF'))'/h;
 %       tgx=(gradient(functionG'))'/h;
 %       tey=(gradient(functionE))/h;
 %       tfy=(gradient(functionF))/h;
 %       tgy=(gradient(functionG))/h;
 %       gama111=h*h*(te2./functionEG+te.*(functionG.*tex-2*functionF.*tfx+functionF.*tey)./(2*functionEG));  %%%functionL/functionEG+gama111*chazhix+gama112*chazhiy
 %       gama221=h*h*(tr2./functionEG+te.*(-functionG.*tgx+2*functionG.*tfy-functionF.*tgy)./(2*functionEG));
 %       clear functionG tr2 te2;
 %       gama112=h*h*tr.*(-functionE.*tey+2*functionE.*tfx-functionF.*tex)./(2*functionEG);
 %       gama222=h*h*tr.*(functionE.*tgy-2*functionF.*tfy+functionF.*tgx)./(2*functionEG);
 %       clear tex tfx tgx tey tfy tgy tr te;
 %       clear functionE functiongF functionG functionEG;
 %       DD=gama111(2:(fenmx-1),2:(fenmy-1))+gama112(2:(fenmx-1),2:(fenmy-1));
 %       DD(1,:)=DD(1,:)-jieguo(1,2:(fenmy-1));
 %       DD(fenmx-2,:)=DD(fenmx-2,:)-jieguo(fenmx,2:(fenmy-1));
 %       D(minx:maxx,miny:maxy)=DD((1+xz):(fenmx-2+xy),(1+yz):(fenmy-2+yy));
 %       clear gama111 gama112 DD;
 %       EE=gama221(2:(fenmx-1),2:(fenmy-1))+gama222(2:(fenmx-1),2:(fenmy-1));
 %       EE(:,1)=EE(:,1)-jieguo(2:(fenmx-1),1);
 %       EE(:,fenmy-2)=EE(:,fenmy-2)-jieguo(2:(fenmx-1),fenmy);
 %       E(minx:maxx,miny:maxy)=EE((1+xz):(fenmx-2+xy),(1+yz):(fenmy-2+yy));
 %       clear gama221 gama222 jieguo EE;
        [DD,EE]=ziquyumoni(jieguo,h);
        D(fenkuaiminx:fenkuaimaxx,fenkuaiminy:fenkuaimaxy)=DD((1+(fenkuaiminx-jisuanminx)):(fenmx-(jisuanmaxx-fenkuaimaxx)),(1+(fenkuaiminy-jisuanminy)):(fenmy-(jisuanmaxy-fenkuaimaxy)));
        E(fenkuaiminx:fenkuaimaxx,fenkuaiminy:fenkuaimaxy)=EE((1+(fenkuaiminx-jisuanminx)):(fenmx-(jisuanmaxx-fenkuaimaxx)),(1+(fenkuaiminy-jisuanminy)):(fenmy-(jisuanmaxy-fenkuaimaxy)));
        clear jieguo EE DD;
    end
end
D(:,my)=[];
E(:,my)=[];
D(mx,:)=[];
E(mx,:)=[];
D(1,:)=[];
E(1,:)=[];
D(:,1)=[];
E(:,1)=[];
clear chazhi;
D=reshape(D',m,1);
E=reshape(E',m,1);
ABDE=zeros(m,1);
ABDE=-2*D-2*E+xiangliangweiyi1(D,my-2)+xiangliangweiyi1(D,-my+2)+xiangliangweiyi2(E,mx,my,1)+xiangliangweiyi2(E,mx,my,-1);
clear D E;

function chazhi=gradient2(jieguo);%%计算差分
[mx my]=size(jieguo);
chazhi=zeros(mx,my);
chazhi(2:(mx-1),:)=jieguo(1:(mx-2),:)+jieguo(3:mx,:)-2*jieguo(2:(mx-1),:);
chazhi(1,:)=(jieguo(3,:)-2*jieguo(2,:)+jieguo(1,:))/2;
chazhi(mx,:)=(jieguo(mx,:)-2*jieguo(mx-1,:)+jieguo(mx-2,:))/2;

function [jisuanminx,jisuanmaxx,jisuanminy,jisuanmaxy,fenkuaiminx,fenkuaimaxx,fenkuaiminy,fenkuaimaxy]=fcjz(jsi,jsj,x,y,chongdie,maxkuai);
%%% (jsi,jsj)块的X和Y各方向的最小序号和最大序号(分别为计算的和取值)
b=maxkuai;
x2=fenchai(x,b); %%% x方向的块数
y2=fenchai(y,b);  %%% y方向块数
x1=floor(x/x2);  %%% x方向各块的点数分别为x1和x1+1，要注意的是，点数为x1的块在前，点数为x1+1的块在后
y1=floor(y/y2);  %%% y方向各块的点数分别为y1和y1+1, 要注意的是，点数为y1的块在前，点数为y1+1的块在后
x3=x-x1*x2;  %%% 点数为x1+1的块数
y3=y-y1*y2;  %%% 点数为y1+1的块数
if jsi<=(x2-x3) %%%
    fenkuaimaxx=jsi*x1;
    fenkuaiminx=fenkuaimaxx-x1+1;
else 
    fenkuaimaxx=x1*(x2-x3)+(jsi-(x2-x3))*(x1+1);
    fenkuaiminx=fenkuaimaxx-x1;
end
if jsj<=(y2-y3)
    fenkuaimaxy=jsj*y1;
    fenkuaiminy=fenkuaimaxy-y1+1;
else 
    fenkuaimaxy=y1*(y2-y3)+(jsj-(y2-y3))*(y1+1);
    fenkuaiminy=fenkuaimaxy-y1;
end
if fenkuaiminx>1
    jisuanminx=fenkuaiminx-chongdie;
else
    jisuanminx=fenkuaiminx;
end
if fenkuaimaxx<x
    jisuanmaxx=fenkuaimaxx+chongdie;
else
    jisuanmaxx=fenkuaimaxx;
end
if fenkuaiminy>1
    jisuanminy=fenkuaiminy-chongdie;
else
    jisuanminy=fenkuaiminy;
end
if fenkuaimaxy<y
    jisuanmaxy=fenkuaimaxy+chongdie;
else
    jisuanmaxy=fenkuaimaxy;
end
    
function a=fenchai(x,y);
a=floor(x/y);
while (x-a*y)>a
    y=y-1;
    a=floor(x/y);
end
 
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

function [D,E]=ziquyumoni(chazhi,h);
[mx,my]=size(chazhi);

fy=gradient(chazhi)/h; %%% tr
fx=(gradient(chazhi'))'/h;  %%%% te
fxx=gradient2(chazhi)/(h*h);
fyy=(gradient2(chazhi'))'/(h*h);

functionF=fx.*fy;
functionE=1+fx.*fx;
functionG=1+fy.*fy;
functionEG=(functionE.*functionG-functionF.^2);
fxx=fxx./(functionE+functionG-1);
fyy=fyy./(functionE+functionG-1);

fex=(gradient(functionE'))'/h;
ffx=(gradient(functionF'))'/h;
fgx=(gradient(functionG'))'/h;
fey=(gradient(functionE))/h;
ffy=(gradient(functionF))/h;
fgy=(gradient(functionG))/h;

D=zeros(size(chazhi));
E=zeros(size(chazhi));

D(2:(mx-1),2:(my-1))=h*h*(fxx(2:(mx-1),2:(my-1))+fx(2:(mx-1),2:(my-1)).*(functionG(2:(mx-1),2:(my-1)).*fex(2:(mx-1),2:(my-1))-2*functionF(2:(mx-1),2:(my-1)).*ffx(2:(mx-1),2:(my-1))+functionF(2:(mx-1),2:(my-1)).*fey(2:(mx-1),2:(my-1)))./(2*functionEG(2:(mx-1),2:(my-1))))+h*h*fy(2:(mx-1),2:(my-1)).*(-functionE(2:(mx-1),2:(my-1)).*fey(2:(mx-1),2:(my-1))+2*functionE(2:(mx-1),2:(my-1)).*ffx(2:(mx-1),2:(my-1))-functionF(2:(mx-1),2:(my-1)).*fex(2:(mx-1),2:(my-1)))./(2*functionEG(2:(mx-1),2:(my-1))); %%%functionL/functionEG+gama111*chazhix+gama112*chazhiy
E(2:(mx-1),2:(my-1))=h*h*(fyy(2:(mx-1),2:(my-1))+fx(2:(mx-1),2:(my-1)).*(-functionG(2:(mx-1),2:(my-1)).*fgx(2:(mx-1),2:(my-1))+2*functionG(2:(mx-1),2:(my-1)).*ffy(2:(mx-1),2:(my-1))-functionF(2:(mx-1),2:(my-1)).*fgy(2:(mx-1),2:(my-1)))./(2*functionEG(2:(mx-1),2:(my-1))))+h*h*fy(2:(mx-1),2:(my-1)).*(functionE(2:(mx-1),2:(my-1)).*fgy(2:(mx-1),2:(my-1))-2*functionF(2:(mx-1),2:(my-1)).*ffy(2:(mx-1),2:(my-1))+functionF(2:(mx-1),2:(my-1)).*fgx(2:(mx-1),2:(my-1)))./(2*functionEG(2:(mx-1),2:(my-1)));

E(:,2)=E(:,2)-chazhi(:,1);
E(:,my-1)=E(:,my-1)-chazhi(:,my);
D(2,:)=D(2,:)-chazhi(1,:);
D(mx-1,:)=D(mx-1,:)-chazhi(mx,:);

clear fxx fyy;
clear fex ffx fgx fey ffy fgy fx fy;
clear functionE functiongF functionG functionEG;

