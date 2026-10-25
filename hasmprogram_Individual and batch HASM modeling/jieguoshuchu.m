
function jieguoshuchu2(chazhi,mulu,mx,my,x0,y0,H); %%%%输入计算结果
    chazhi=chazhi';
        fid=fopen(mulu,'w');
        fprintf(fid,['ncols       ',num2str(mx)]);
        fprintf(fid,'\r\n');
        fprintf(fid,['nrows       ',num2str(my)]);
        fprintf(fid,'\r\n');
        fprintf(fid,['xllcorner  ',num2str(x0)]);
        fprintf(fid,'\r\n');
        fprintf(fid,['yllcorner  ',num2str(y0)]);
        fprintf(fid,'\r\n');
        fprintf(fid,['cellsize  ',num2str(H)]);
        fprintf(fid,'\r\n');
        fprintf(fid,'NODATA_value  -9999');
        fprintf(fid,'\r\n');
        for i=my:-1:1
            for j=1:(mx-1)
                if chazhi(i,j)==-9999
                    fprintf(fid,'%4.0f ',chazhi(i,j));
                else
                    fprintf(fid,'%5.4f ',chazhi(i,j));
                end
            end
            if chazhi(i,mx)==-9999
                fprintf(fid,'%4.0f',chazhi(i,mx));
            else
                fprintf(fid,'%5.4f',chazhi(i,mx));
            end
            fprintf(fid,'\r\n');
        end
        fclose(fid);

