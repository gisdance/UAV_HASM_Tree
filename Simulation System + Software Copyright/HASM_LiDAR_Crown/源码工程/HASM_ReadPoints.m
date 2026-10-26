function points = HASM_ReadPoints(filename)
%HASM_READPOINTS Read XYZ samples from CSV, XLS, XLSX, or TXT.
%   POINTS is an N-by-3 double array in x, y, z column order.

if ~ischar(filename) || isempty(filename)
    error('HASM:Points:Path', 'Input filename must be a nonempty character vector.');
end
if exist(filename, 'file') ~= 2
    error('HASM:Points:Missing', 'Point file does not exist: %s', filename);
end

[~, ~, ext] = fileparts(filename);
ext = lower(ext);
if ~ismember(ext, {'.csv', '.xls', '.xlsx', '.txt', '.xyz'})
    error('HASM:Points:Format', 'Supported point formats are CSV, XLS, XLSX, TXT, and XYZ.');
end

% A named table handles the source CSV's extra text index column.
[points, hasXYZNames] = localReadNamedTable(filename);
if ~hasXYZNames
    if strcmp(ext, '.xls') || strcmp(ext, '.xlsx')
        try
            points = xlsread(filename);
        catch ME
            error('HASM:Points:Read', 'Could not read point file %s: %s', filename, ME.message);
        end
        if size(points, 2) ~= 3
            error('HASM:Points:Columns', ...
                'Spreadsheet needs x/y/z headers or exactly three numeric columns.');
        end
    else
        points = localReadDelimited(filename);
    end
end

if ~isnumeric(points) || ~isreal(points) || size(points, 2) ~= 3
    error('HASM:Points:Columns', 'Point file must contain numeric x, y, z columns.');
end
points = double(points);
if size(points, 1) < 3
    error('HASM:Points:Count', 'At least three point records are required.');
end
if any(~isfinite(points(:)))
    error('HASM:Points:Values', 'Point coordinates and elevations must be finite numbers.');
end
if size(unique(points(:, 1:2), 'rows'), 1) < 3
    error('HASM:Points:Count', 'At least three distinct XY locations are required.');
end
end

function [points, hasXYZNames] = localReadNamedTable(filename)
points = [];
hasXYZNames = false;
try
    tableData = readtable(filename);
catch
    return;
end

names = tableData.Properties.VariableNames;
indices = zeros(1, 3);
expected = {'x', 'y', 'z'};
for i = 1:numel(names)
    key = regexprep(lower(names{i}), '[^a-z0-9]', '');
    for j = 1:3
        if strcmp(key, expected{j})
            indices(j) = i;
        end
    end
end
if any(indices == 0)
    return;
end

hasXYZNames = true;
points = zeros(height(tableData), 3);
for j = 1:3
    points(:, j) = localToDouble(tableData{:, indices(j)});
end
end

function values = localToDouble(column)
if isnumeric(column) || islogical(column)
    values = double(column);
elseif iscell(column)
    values = NaN(numel(column), 1);
    for i = 1:numel(column)
        item = column{i};
        if isnumeric(item) && isscalar(item)
            values(i) = double(item);
        elseif ischar(item)
            values(i) = str2double(item);
        end
    end
elseif ischar(column)
    values = str2double(cellstr(column));
else
    try
        values = str2double(cellstr(column));
    catch
        values = NaN(numel(column), 1);
    end
end
values = values(:);
end

function points = localReadDelimited(filename)
fid = fopen(filename, 'r');
if fid < 0
    error('HASM:Points:Read', 'Could not open point file: %s', filename);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
points = zeros(0, 3);
lineNumber = 0;
while true
    line = fgetl(fid);
    if ~ischar(line)
        break;
    end
    lineNumber = lineNumber + 1;
    line = strtrim(line);
    if isempty(line) || line(1) == '#' || line(1) == '%'
        continue;
    end
    tokens = regexp(line, '[,;\s]+', 'split');
    numbers = str2double(tokens);
    numericColumns = find(isfinite(numbers));
    if isempty(points) && isempty(numericColumns)
        % Allow a text header before the first data row.
        continue;
    end
    if numel(numericColumns) ~= 3
        error('HASM:Points:Columns', ...
            'Expected exactly three finite numeric values on line %d of %s.', ...
            lineNumber, filename);
    end
    points(end + 1, :) = numbers(numericColumns); %#ok<AGROW>
end
end
