function [grid, meta] = HASM_Run(pointsFile, initialGridFile, maskGridFile, outputFile, opts)
%HASM_RUN Run the original HASM solver with portable input and output paths.
%   [GRID,META] = HASM_RUN(POINTS,INITIAL,MASK,OUTPUT) reads XYZ samples
%   and ArcGIS ASCII grids, runs the original solver, and writes OUTPUT.

if nargin < 4
    error('HASM:Arguments', 'Four file paths are required.');
end
if nargin < 5 || isempty(opts)
    opts = struct();
end

[initialGrid, meta] = HASM_ReadGrid(initialGridFile);
if any(initialGrid(:) == meta.nodata)
    error('HASM:Grid:NoData', ...
        'Initial grid must have finite elevations throughout, including outside the mask.');
end
points = HASM_ReadPoints(pointsFile);
if ~isempty(maskGridFile)
    [maskGrid, maskMeta] = HASM_ReadGrid(maskGridFile);
    if ~isequal(size(maskGrid), size(initialGrid)) || ...
            abs(maskMeta.xllcorner-meta.xllcorner) > 1e-6 || ...
            abs(maskMeta.yllcorner-meta.yllcorner) > 1e-6 || ...
            abs(maskMeta.cellsize-meta.cellsize) > 1e-9
        error('HASM:Mask', 'Mask and initial grid geometry do not match.');
    end
else
    maskGrid = [];
end

mx = meta.ncols;
my = meta.nrows;
if mx < 4 || my < 4
    error('HASM:Grid', 'Grid must have at least 4 rows and columns.');
end
H = meta.cellsize;
if ~isfinite(H) || H <= 0
    error('HASM:Grid', 'Invalid cell size.');
end

% Keep the coordinate transform and interior filtering of shujuxls.m.
h = 1 / (mx - 1);
XX = meta.xllcorner + H / 2;
YY = meta.yllcorner + H / 2;
samples = points;
samples(:,1) = (samples(:,1)-XX) / ((mx-1)*H);
samples(:,2) = (samples(:,2)-YY) / ((mx-1)*H);
inside = samples(:,1) >= h & samples(:,1) <= (mx-2)*h & ...
         samples(:,2) >= h & samples(:,2) <= (my-2)*h;
samples = samples(inside,:);
if size(samples,1) < 8
    error('HASM:Samples', 'Fewer than 8 sample points remain inside the grid.');
end

global wuchaid CGerror CGmaxtimes guimo caiyangid lamdazhi ...
       jizhiid lamdaid pinghuaid hasmtime hasmerror yuchuliid ...
       banjing songchi raodong luid;
CGerror = 1e-9;
CGmaxtimes = 5000;
guimo = 2000000;
lamdaid = 0;
hasmerror = 1e-12;
yuchuliid = 1;
wuchaid = 1;
raodong = 0;
canshus = [5 0.6 3 1 3 2 6 1];
if isfield(opts,'canshus')
    if ~isnumeric(opts.canshus) || numel(opts.canshus) ~= 8
        error('HASM:Options', 'opts.canshus must contain eight numbers.');
    end
    canshus = double(opts.canshus(:)');
end
if isfield(opts,'guimo')
    guimo = opts.guimo;
end
lamdazhi = canshus(1);
songchi = canshus(2);
jizhiid = canshus(3);
pinghuaid = canshus(4);
caiyangid = canshus(5);
hasmtime = canshus(6);
banjing = canshus(7);
luid = canshus(8);
if pinghuaid == 1
    lamdaid = 2;
end
if caiyangid == 1
    yuchuliid = 1;
end

% The solver uses x as its first matrix dimension and reverses ASCII rows.
internalGrid = flipud(initialGrid)';
result = hasm(internalGrid, samples, h);
if ~isempty(maskGrid)
    internalMask = flipud(maskGrid)';
    result(internalMask == maskMeta.nodata) = meta.nodata;
end
grid = flipud(result');
if ~isequal(size(grid), size(initialGrid))
    error('HASM:Result', 'Solver returned a grid of unexpected size.');
end
HASM_WriteGrid(outputFile, grid, meta);
end
