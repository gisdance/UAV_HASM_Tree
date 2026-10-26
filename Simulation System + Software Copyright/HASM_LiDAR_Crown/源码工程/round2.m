
function b=round2(x)
%%%%%%%最接近的整数，如果跟两个整数距离相等，则取小的那个
a=abs(x-round(x));
if a==0.5
    b=round(x)-1;
else
    b=round(x);
end