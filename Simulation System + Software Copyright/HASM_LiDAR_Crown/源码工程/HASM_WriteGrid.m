function HASM_WriteGrid(path, grid, meta)
%HASM_WRITEGRID Write an ArcGIS ASCII raster without changing orientation.
if ~isequal(size(grid), [meta.nrows meta.ncols])
    error('HASM:Grid', 'Grid size does not match metadata.');
end
[folder,~,~] = fileparts(path);
if ~isempty(folder) && exist(folder,'dir') ~= 7
    [ok,msg] = mkdir(folder);
    if ~ok
        error('HASM:Output', 'Cannot create output directory: %s', msg);
    end
end
fid = fopen(path,'wt');
if fid < 0
    error('HASM:Output', 'Cannot open output file: %s', path);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'ncols         %d\n',meta.ncols);
fprintf(fid,'nrows         %d\n',meta.nrows);
fprintf(fid,'xllcorner     %.15g\n',meta.xllcorner);
fprintf(fid,'yllcorner     %.15g\n',meta.yllcorner);
fprintf(fid,'cellsize      %.15g\n',meta.cellsize);
fprintf(fid,'NODATA_value  %.15g\n',meta.nodata);
format = [repmat('%.10g ',1,meta.ncols-1) '%.10g\n'];
for row = 1:meta.nrows
    fprintf(fid,format,grid(row,:));
end
end
