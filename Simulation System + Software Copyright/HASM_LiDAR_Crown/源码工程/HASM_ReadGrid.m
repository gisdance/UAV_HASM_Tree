function [grid, meta] = HASM_ReadGrid(filename)
%HASM_READGRID Read an ArcGIS ASCII raster in its external row orientation.
%   META has ncols, nrows, xllcorner, yllcorner, cellsize, and nodata.

if ~ischar(filename) || isempty(filename)
    error('HASM:Grid:Path', 'Input filename must be a nonempty character vector.');
end
if exist(filename, 'file') ~= 2
    error('HASM:Grid:Missing', 'Raster file does not exist: %s', filename);
end

fid = fopen(filename, 'r');
if fid < 0
    error('HASM:Grid:Read', 'Could not open raster file: %s', filename);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

meta = struct('ncols', [], 'nrows', [], 'xllcorner', [], ...
    'yllcorner', [], 'cellsize', [], 'nodata', -9999);
xCenter = [];
yCenter = [];
for i = 1:6
    position = ftell(fid);
    line = fgetl(fid);
    if ~ischar(line)
        error('HASM:Grid:Header', 'Raster header is incomplete: %s', filename);
    end
    parts = regexp(strtrim(line), '^([A-Za-z_]+)\s+(.+)$', 'tokens', 'once');
    if isempty(parts)
        if i == 6 && ~isempty(meta.cellsize)
            fseek(fid, position, 'bof');
            break;
        end
        error('HASM:Grid:Header', 'Invalid raster header line %d.', i);
    end
    key = lower(parts{1});
    value = str2double(strtrim(parts{2}));
    if ~isfinite(value)
        error('HASM:Grid:Header', 'Invalid numeric value for %s.', key);
    end
    switch key
        case 'ncols'
            meta.ncols = value;
        case 'nrows'
            meta.nrows = value;
        case 'xllcorner'
            meta.xllcorner = value;
        case 'yllcorner'
            meta.yllcorner = value;
        case 'xllcenter'
            xCenter = value;
        case 'yllcenter'
            yCenter = value;
        case 'cellsize'
            meta.cellsize = value;
        case 'nodata_value'
            meta.nodata = value;
        otherwise
            error('HASM:Grid:Header', 'Unexpected raster header field: %s', key);
    end
end

if isempty(meta.ncols) || isempty(meta.nrows) || isempty(meta.cellsize)
    error('HASM:Grid:Header', 'Raster header lacks dimensions or cellsize.');
end
if meta.ncols < 1 || meta.nrows < 1 || ...
        meta.ncols ~= floor(meta.ncols) || meta.nrows ~= floor(meta.nrows) || ...
        meta.cellsize <= 0
    error('HASM:Grid:Header', 'Raster dimensions and cellsize must be positive.');
end
if isempty(meta.xllcorner)
    if isempty(xCenter)
        error('HASM:Grid:Header', 'Raster header lacks xllcorner/xllcenter.');
    end
    meta.xllcorner = xCenter - meta.cellsize / 2;
end
if isempty(meta.yllcorner)
    if isempty(yCenter)
        error('HASM:Grid:Header', 'Raster header lacks yllcorner/yllcenter.');
    end
    meta.yllcorner = yCenter - meta.cellsize / 2;
end

raw = fscanf(fid, '%f', [meta.ncols, meta.nrows]);
if numel(raw) ~= meta.ncols * meta.nrows
    error('HASM:Grid:Size', 'Raster body does not match ncols and nrows: %s', filename);
end
grid = double(raw');
if any(~isfinite(grid(:)))
    error('HASM:Grid:Values', 'Raster body contains nonfinite values: %s', filename);
end
remaining = fread(fid, Inf, '*char')';
if ~isempty(strtrim(remaining))
    error('HASM:Grid:Size', 'Raster body has extra values or text: %s', filename);
end
end
