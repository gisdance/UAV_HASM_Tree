function [GG,GH]=taylorcaiyang(x,y,z,chazhi,lisangzhi,h);%%%% 生成采样矩阵和向量
global caiyangid;
%%%%%  caiyangid=5 采用5阶截断，一个采样方程，需要联系9个点，
%%%%%  返回的GG为(mx-2)*(my-2)的方阵GG=lamda*lamda*G'G;  GH=lamda*lamda*G'H
canshu=1/30; %%%%%这个是直接取值，不泰勒展开的参数，采样点与网格的距离小于h/30则直接取值。
if isempty(x)
    GG=0;
    Gh=0;
else
    [mx,my]=size(chazhi);
    xid=round2(x./h); %%% 距离采样点(x,y)最近的网格点在所有内点网格中的x序号
    yid=round2(y./h); %%% 距离采样点(x,y)最近的网格点在所有内点网格中的y序号
    caiyangxulie=(xid-1).*(my-2)+yid; 
    ccx=x-xid.*h;   %%% 采样点(x,y)与离他最近的网格点的横向距离
    ccy=y-yid.*h;   %%% 采样点(x,y)与离他最近的网格点的纵向距离
    clear x y;
    mx=mx-2;
    my=my-2;
    n=mx*my;
    G=sparse(zeros(1,n)); 
    H=zeros(length(xid),1);
    for i=1:length(ccx)
        temp=caiyangxulie(i);
        cx=ccx(i);
        cy=ccy(i);
        if caiyangid==1
            G(i,temp)=lisangzhi(i);
            H(i)=z(i)*lisangzhi(i);
        else
            if sqrt(cx^2+cy^2)<(canshu*h)
                G(i,temp)=lisangzhi(i);
                H(i)=z(i)*lisangzhi(i);
            else
                if xid(i)==1
                    if yid(i)==1
                        H(i)=z(i)-0.5*(cx^2/h^2-cx/h)*chazhi(xid(i),yid(i)+1)-0.5*(cy^2/h^2-cy/h)*chazhi(xid(i)+1,yid(i));
                        H(i)=H(i)+(0.25*cx*cy/h^2)*(chazhi(xid(i)+2,yid(i))+chazhi(xid(i),yid(i)+2)-chazhi(xid(i),yid(i)));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
                        G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
%                       G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
                        G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
%                       G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
                        G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
%                       G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
%                       G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
%                       G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    elseif yid(i)==my
                        H(i)=z(i)-0.5*(cx^2/h^2-cx/h)*chazhi(xid(i),yid(i)+1)-0.5*(cy^2/h^2+cy/h)*chazhi(xid(i)+1,yid(i)+2);
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(chazhi(xid(i)+2,yid(i)+2)-chazhi(xid(i),yid(i)+2)+chazhi(xid(i),yid(i)));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
                        G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
%                       G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
%                       G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
                        G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
%                       G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
                        G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
%                       G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
%                       G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    else
                        H(i)=z(i)-0.5*(cx^2/h^2-cx/h)*chazhi(xid(i),yid(i)+1);
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(-chazhi(xid(i),yid(i)+2)+chazhi(xid(i),yid(i)));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
                        G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
%                       G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
                        G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
                        G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
                        G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
                        G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
%                       G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
%                       G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    end  %%% 完成xid(i)=1的各种情形的计算
                elseif xid(i)==mx
                    if yid(i)==1
                        H(i)=z(i)-0.5*(cx/h+cx^2/h^2)*chazhi(xid(i)+2,yid(i)+1)-0.5*(cy^2/h^2-cy/h)*chazhi(xid(i)+1,yid(i));
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(chazhi(xid(i)+2,yid(i)+2)-chazhi(xid(i)+2,yid(i))+chazhi(xid(i),yid(i)));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
%                       G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
                        G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
                        G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
%                       G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
%                       G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
%                       G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
                        G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
%                       G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    elseif yid(i)==my
                        H(i)=z(i)-0.5*(cx^2/h^2-cx/h)*chazhi(xid(i)+2,yid(i)+1)-0.5*(cy/h+cy^2/h^2)*chazhi(xid(i)+1,yid(i)+2);
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(chazhi(xid(i)+2,yid(i)+2)-chazhi(xid(i)+2,yid(i))-chazhi(xid(i),yid(i)+2));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
%                       G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
                        G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
%                       G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
                        G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
%                       G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
%                       G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
    %                   G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
                        G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    else
                        H(i)=z(i)-0.5*(cx/h+cx^2/h^2)*chazhi(xid(i)+2,yid(i)+1);
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(chazhi(xid(i)+2,yid(i)+2)-chazhi(xid(i)+2,yid(i)));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
%                       G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
                        G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
                        G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
                        G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
%                       G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
%                       G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
                        G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
                        G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    end %%%% 完成 xid(i)=mx的各种情形的计算
                else
                    if yid(i)==1
                        H(i)=z(i)-0.5*(cy^2/h^2-cy/h)*chazhi(xid(i)+1,yid(i));
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(-chazhi(xid(i)+2,yid(i))+chazhi(xid(i),yid(i)));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
                        G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
                        G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
                        G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
%                       G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
                        G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
%                       G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
                        G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
%                       G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    elseif yid(i)==my
                        H(i)=z(i)-0.5*(cy/h+cy^2/h^2)*chazhi(xid(i)+1,yid(i)+2);
                        H(i)=H(i)-(0.25*cx*cy/h^2)*(chazhi(xid(i)+2,yid(i)+2)-chazhi(xid(i),yid(i)+2));
                        G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
                        G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
                        G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
%                       G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
                        G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
    %                   G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
                        G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
%                       G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
                        G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                        G(i,:)=G(i,:)*lisangzhi(i);
                        H(i)=H(i)*lisangzhi(i);
                    else  %%%% 完成 xid(i)~=1,mx,但yid(i)=1或者my的计算
                        if caiyangid==3
                            H(i)=z(i);
                            G(i,temp)=1-(cx^2+cy^2)./h^2;          %%%  (i,j)
                            G(i,temp+my)=0.5*(cx/h+cx^2/h^2);      %%%  (i+1,j)
                            G(i,temp-my)=0.5*(cx^2/h^2-cx/h);      %%%  (i-1,j)
                            G(i,temp+1)=0.5*(cy/h+cy^2/h^2);       %%%  (i,j+1) 
                            G(i,temp-1)=0.5*(cy^2/h^2-cy/h);       %%%  (i,j-1)  
                            G(i,temp+my+1)=0.25*cx*cy/h^2;         %%%  (i+1,j+1)
                            G(i,temp+my-1)=-0.25*cx*cy/h^2;        %%%  (i+1,j-1)
                            G(i,temp-my+1)=-0.25*cx*cy/h^2;        %%%  (i-1,j+1)
                            G(i,temp-my-1)=0.25*cx*cy/h^2;         %%%  (i-1,j-1)
                            G(i,:)=G(i,:)*lisangzhi(i);
                            H(i)=H(i)*lisangzhi(i);
                        elseif caiyangid==5
                            if xid(i)==2
                                if yid(i)==2
                                    H(i)=z(i)-(-(cy*cx^3)/(24*h^4))*chazhi(xid(i)-1,yid(i)+2)-(-cx^3/(12*h^3)+cx^4/(24*h^4))*chazhi(xid(i)-1,yid(i)+1);
                                    H(i)=H(i)-((cy*cx^3)/(24*h^4))*chazhi(xid(i)-1,yid(i))-((cx*cy^3)/(24*h^4))*chazhi(xid(i),yid(i)-1);
                                    H(i)=H(i)-(-cy^3/(12*h^3)+cy^4/(24*h^4))*chazhi(xid(i)+1,yid(i)-1)-(-cx*cy^3/(24*h^4))*chazhi(xid(i)+2,yid(i)-1);
                                    G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
                                    G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
%                                   G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
%                                   G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
%                                   G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
                                    G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
%                                   G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
%                                   G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
%                                   G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                elseif yid(i)==(my-1)
                                    H(i)=z(i)-(-(cx*cy^3)/(24*h^4))*chazhi(xid(i),yid(i)+3)-(cy^3/(12*h^3)+cy^4/(24*h^4))*chazhi(xid(i)+1,yid(i)+3);
                                    H(i)=H(i)-((cx*cy^3)/(24*h^4))*chazhi(xid(i)+2,yid(i)+3)-(-(cy*cx^3)/(24*h^4))*chazhi(xid(i)-1,yid(i)+2);
                                    H(i)=H(i)-(-cx^3/(12*h^3)+cx^4/(24*h^4))*chazhi(xid(i)-1,yid(i)+1)-((cy*cx^3)/(24*h^4))*chazhi(xid(i)-1,yid(i));
%                                   G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
%                                   G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
%                                   G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
%                                   G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
%                                   G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
%                                   G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
                                    G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                else
                                    H(i)=z(i)-(-(cy*cx^3)/(24*h^4))*chazhi(xid(i)-1,yid(i)+2)-(-cx^3/(12*h^3)+cx^4/(24*h^4))*chazhi(xid(i)-1,yid(i)+1)-((cy*cx^3)/(24*h^4))*chazhi(xid(i)-1,yid(i));
                                    G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
                                    G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
%                                   G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
%                                   G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
%                                   G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
                                    G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                end  %%%%  完成 xid(i)=2,caiyangid=5的计算
                            elseif xid(i)==(mx-1)
                                if yid(i)==2
                                    H(i)=z(i)-((cy*cx^3)/(24*h^4))*chazhi(xid(i)+3,yid(i)+2)-(cx^3/(12*h^3)+cx^4/(24*h^4))*chazhi(xid(i)+3,yid(i)+1);
                                    H(i)=H(i)-(-(cy*cx^3)/(24*h^4))*chazhi(xid(i)+3,yid(i))-((cx*cy^3)/(24*h^4))*chazhi(xid(i),yid(i)-1);
                                    H(i)=H(i)-(-cy^3/(12*h^3)+cy^4/(24*h^4))*chazhi(xid(i)+1,yid(i)-1)-(-cx*cy^3/(24*h^4))*chazhi(xid(i)+2,yid(i)-1);
                                    G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
                                    G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
%                                   G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
%                                   G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
%                                   G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
%                                   G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
%                                   G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
%                                   G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                elseif yid(i)==(my-1)
                                    H(i)=z(i)-(-(cx*cy^3)/(24*h^4))*chazhi(xid(i),yid(i)+3)-(cy^3/(12*h^3)+cy^4/(24*h^4))*chazhi(xid(i)+1,yid(i)+3);
                                    H(i)=H(i)-((cx*cy^3)/(24*h^4))*chazhi(xid(i)+2,yid(i)+3)-((cy*cx^3)/(24*h^4))*chazhi(xid(i)+3,yid(i)+2);
                                    H(i)=H(i)-(cx^3/(12*h^3)+cx^4/(24*h^4))*chazhi(xid(i)+3,yid(i)+1)-(-(cy*cx^3)/(24*h^4))*chazhi(xid(i)+3,yid(i));
%                                   G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
%                                   G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
%                                   G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
%                                   G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
%                                   G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
%                                   G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                else
                                    H(i)=z(i)-((cy*cx^3)/(24*h^4))*chazhi(xid(i)+3,yid(i)+2)-(cx^3/(12*h^3)+cx^4/(24*h^4))*chazhi(xid(i)+3,yid(i)+1)-(-(cy*cx^3)/(24*h^4))*chazhi(xid(i)+3,yid(i));
                                    G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
                                    G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
%                                   G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
%                                   G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
%                                   G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                end %%%%  完成 xid(i)=mx-1,caiyangid=5的计算
                            else  
                                if yid(i)==2
                                    H(i)=z(i)-((cx*cy^3)/(24*h^4))*chazhi(xid(i),yid(i)-1);
                                    H(i)=H(i)-(-cy^3/(12*h^3)+cy^4/(24*h^4))*chazhi(xid(i)+1,yid(i)-1)-(-cx*cy^3/(24*h^4))*chazhi(xid(i)+2,yid(i)-1);
                                    G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
                                    G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
                                    G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
%                                   G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
%                                   G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
%                                   G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                elseif yid(i)==(my-1)
                                    H(i)=z(i)-(-(cx*cy^3)/(24*h^4))*chazhi(xid(i),yid(i)+3)-(cy^3/(12*h^3)+cy^4/(24*h^4))*chazhi(xid(i)+1,yid(i)+3);
                                    H(i)=H(i)-((cx*cy^3)/(24*h^4))*chazhi(xid(i)+2,yid(i)+3);
%                                   G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
%                                   G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
%                                   G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
                                    G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                else
                                    H(i)=z(i);
                                    G(i,temp-my+2)=-(cx*cy^3)/(24*h^4);
                                    G(i,temp+2)=cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my+2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2*my+1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp+2*my+1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp+my+1)=cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)-(cx*cy^3+cy*cx^3)/(12*h^4)+(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-my+1)=-cx*cy/(4*h^2)+(cx*cy)^2/(4*h^4)+(cx*cy^3+cy*cx^3)/(12*h^4)+(-cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp+1)=cy/(2*h)+cy^2/(2*h^2)-(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp-2*my)=-cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-my)=-cx/(2*h)+cx^2/(2*h^2)+(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp)=1-(cx^2+cy^2)/(h^2)+(cx^4+4*(cx*cy)^2+cy^4)/(4*h^4);
                                    G(i,temp+my)=cx/(2*h)+cx^2/(2*h^2)-(cx^3+3*cx*cy^2)/(6*h^3)-(cx^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+2*my)=cx^3/(12*h^3)+cx^4/(24*h^4);
                                    G(i,temp-2*my-1)=(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-1)=cx*cy/(4*h^2)-(cx*cy^3-3*(cx*cy)^2+cy*cx^3)/(12*h^4)-(cx*cy^2+cy*cx^2)/(4*h^3);
                                    G(i,temp-1)=-cy/(2*h)+cy^2/(2*h^2)+(cy^3+3*cy*cx^2)/(6*h^3)-(cy^4+3*(cx*cy)^2)/(6*h^4);
                                    G(i,temp+my-1)=-cx*cy/(4*h^2)+(cx*cy^3+3*(cx*cy)^2+cy*cx^3)/(12*h^4)+(cx*cy^2-cy*cx^2)/(4*h^3);
                                    G(i,temp+2*my-1)=-(cy*cx^3)/(24*h^4);
                                    G(i,temp-my-2)=(cx*cy^3)/(24*h^4);
                                    G(i,temp-2)=-cy^3/(12*h^3)+cy^4/(24*h^4);
                                    G(i,temp+my-2)=-cx*cy^3/(24*h^4);
                                    G(i,:)=G(i,:)*lisangzhi(i);
                                    H(i)=H(i)*lisangzhi(i);
                                end
                            end  
                        end %%%% 完成xid(i)~=2,~=mx-1,caiyangid=5的计算
                    end
                end
            end %%%end xid(i)=1,mx
        end  %%% end caiyangid=3,5
    end %%% end length(x)
    clear chazhi z ccx ccy xid yid caiyangxulie;
    GG=G'*G;
    GH=G'*H;
    %clear G H;
end

    