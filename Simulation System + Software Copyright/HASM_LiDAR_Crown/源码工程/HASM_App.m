function fig = HASM_App()
%HASM_APP Classic MATLAB GUI for the LiDAR/HASM demonstration.
% Compatible with MATLAB R2016b and the MATLAB Compiler runtime.
% Required functions in the same package:
%   HASM_ReadPoints(path) -> N-by-3 double
%   HASM_ReadGrid(path) -> [grid, meta]
%   HASM_Run(pointsFile, initialGridFile, maskGridFile, outputFile)
%       -> [grid, meta], and writes outputFile.

appDir = fileparts(mfilename('fullpath'));
if isdeployed
    % Compiler extracts bundled data under ctfroot. Keep results outside it.
    dataDir = fullfile(ctfroot, 'data');
    resultDir = fullfile(pwd, 'results');
else
    dataDir = fullfile(appDir, 'data');
    resultDir = fullfile(appDir, 'results');
end

S.pointsFile = fullfile(dataDir, 'tree.csv');
S.initialFile = fullfile(dataDir, 'tree_initial.asc');
S.maskFile = fullfile(dataDir, 'tree_mask.asc');
S.outputFile = fullfile(resultDir, 'tree_hasm_run.asc');
S.outputChosen = false;
S.referenceFile = fullfile(dataDir, 'tree_hasm_reference.asc');
S.points = [];
S.pointsLoadedFrom = '';
S.resultGrid = [];
S.resultMeta = struct();
S.resultIsReference = false;
S.resultSourceFile = '';
S.busy = false;

fig = figure('Name', '基于HASM模型的LiDAR点云树冠高精度Matlab仿真系统', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Resize', 'off', 'Units', 'pixels', 'Position', [100 100 483 404], ...
    'Color', [0.94 0.94 0.94], 'Visible', 'off', ...
    'CloseRequestFcn', @onClose);

fileMenu = uimenu(fig, 'Label', '文件');
uimenu(fileMenu, 'Label', '读取点云数据...', 'Callback', @onLoadPoints);
uimenu(fileMenu, 'Label', '选择初始栅格...', 'Callback', @onSelectInitial);
uimenu(fileMenu, 'Label', '选择掩膜栅格...', 'Callback', @onSelectMask);
uimenu(fileMenu, 'Label', '设置结果文件...', 'Callback', @onSelectOutput);
uimenu(fileMenu, 'Label', '打开已有HASM结果...', 'Separator', 'on', ...
    'Callback', @onOpenResult);
uimenu(fileMenu, 'Label', '恢复默认路径', 'Separator', 'on', ...
    'Callback', @onRestoreDefaults);
exampleMenu = uimenu(fig, 'Label', '示例');
uimenu(exampleMenu, 'Label', 'tree.csv 树冠', ...
    'Callback', @(~, ~) onSelectExample('tree'));
uimenu(exampleMenu, 'Label', 'shrup.csv 灌木', ...
    'Callback', @(~, ~) onSelectExample('shrup'));
helpMenu = uimenu(fig, 'Label', '帮助');
uimenu(helpMenu, 'Label', '使用步骤', 'Callback', @onHelp);

% Positions match the original App Designer figure (483-by-404 pixels).
S.loadButton = makeButton([175.5 356 135 22], ...
    '读取原始点云xyz数据', @onLoadPoints);
S.table = uitable(fig, 'Units', 'pixels', 'Position', [92 161 302 185], ...
    'Data', zeros(0, 3), 'ColumnName', {'x', 'y', 'z'}, ...
    'RowName', [], 'ColumnEditable', [false false false], ...
    'ColumnWidth', {94 94 94});
S.raw2Button = makeButton([72.5 134 111 22], '查看二维点云', @onRaw2D);
S.raw3Button = makeButton([187.5 134 111 22], '查看三维点云', @onRaw3D);
S.dtmButton = makeButton([302.5 134 113 22], ...
    '查看三维点云DTM', @onDTM);
S.runButton = makeButton([183 99 122 28], ...
    '点击进行HASM构建', @onRun);
S.result2Button = makeButton([183 68 122 22], ...
    '查看二维HASM结果', @onResult2D);
S.meshButton = makeButton([92 39 146 22], ...
    '查看网格HASM点云模型', @onMesh);
S.surfButton = makeButton([248 39 146 22], ...
    '查看精细HASM点云模型', @onSurface);
S.status = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', ...
    'Position', [11 7 461 23], 'BackgroundColor', get(fig, 'Color'), ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'String', '就绪：请选择点云文件，或使用 data 文件夹中的默认数据。');

refreshButtons();
if exist(S.referenceFile, 'file') == 2
    try
        [g, meta] = HASM_ReadGrid(S.referenceFile);
        validateGrid(g);
        S.resultGrid = g;
        S.resultMeta = meta;
        S.resultIsReference = true;
        S.resultSourceFile = S.referenceFile;
        setStatus('已载入预计算的模拟示例结果；点击构建可重新计算。');
    catch ME
        setStatus(['预置示例结果读取失败：' ME.message]);
    end
    refreshButtons();
end
set(fig, 'Visible', 'on');

    function h = makeButton(position, label, callback)
        h = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'pixels', ...
            'Position', position, 'String', label, 'FontSize', 10, ...
            'Callback', callback);
    end

    function setStatus(message)
        if ishandle(fig) && ishandle(S.status)
            set(S.status, 'String', message);
            drawnow;
        end
    end

    function refreshButtons()
        if ~ishandle(fig)
            return;
        end
        if S.busy
            set(S.runButton, 'Enable', 'off');
            set(fileMenu, 'Enable', 'off');
            set(exampleMenu, 'Enable', 'off');
        else
            set(S.runButton, 'Enable', 'on');
            set(fileMenu, 'Enable', 'on');
            set(exampleMenu, 'Enable', 'on');
        end
        if isempty(S.resultGrid) || S.busy
            resultEnabled = 'off';
        else
            resultEnabled = 'on';
        end
        set([S.result2Button S.meshButton S.surfButton], ...
            'Enable', resultEnabled);
    end

    function onLoadPoints(~, ~)
        selected = chooseFile(S.pointsFile, ...
            {'*.csv;*.txt;*.xyz;*.xls;*.xlsx', '点云数据文件'; '*.*', '所有文件'}, ...
            '选择 XYZ 点云文件');
        if isempty(selected)
            return;
        end
        try
            loadPoints(selected);
        catch ME
            showError('读取点云失败', ME);
        end
    end

    function loadPoints(path)
        if exist(path, 'file') ~= 2
            error('找不到点云文件：%s', path);
        end
        points = HASM_ReadPoints(path);
        if ~isnumeric(points) || ~isreal(points) || ...
                size(points, 2) ~= 3 || isempty(points) || ...
                any(~isfinite(points(:)))
            error('点云文件必须包含有限数值的 x、y、z 三列。');
        end
        S.points = double(points);
        S.pointsFile = path;
        S.pointsLoadedFrom = path;
        shown = min(size(points, 1), 200);
        set(S.table, 'Data', points(1:shown, :));
        invalidateComputedResult();
        if S.resultIsReference
            suffix = '；当前结果图仍为预置示例结果';
        else
            suffix = '';
        end
        setStatus(sprintf('已读取 %d 个点，表格显示前 %d 个%s。', ...
            size(points, 1), shown, suffix));
    end

    function onSelectInitial(~, ~)
        selected = chooseFile(S.initialFile, ...
            {'*.txt;*.asc', 'ASCII 栅格文件'; '*.*', '所有文件'}, ...
            '选择 HASM 初始栅格');
        if isempty(selected)
            return;
        end
        S.initialFile = selected;
        invalidateComputedResult();
        setStatus(['初始栅格：' selected]);
    end

    function onSelectMask(~, ~)
        selected = chooseFile(S.maskFile, ...
            {'*.txt;*.asc', 'ASCII 栅格文件'; '*.*', '所有文件'}, ...
            '选择模拟区域掩膜栅格');
        if isempty(selected)
            return;
        end
        S.maskFile = selected;
        invalidateComputedResult();
        setStatus(['掩膜栅格：' selected]);
    end

    function onSelectOutput(~, ~)
        chooseOutput();
    end

    function ok = chooseOutput()
        ok = false;
        startPath = S.outputFile;
        if exist(fileparts(startPath), 'dir') ~= 7
            if isdeployed
                startPath = fullfile(pwd, 'tree_hasm_run.asc');
            else
                startPath = fullfile(appDir, 'tree_hasm_run.asc');
            end
        end
        [name, folder] = uiputfile({'*.asc;*.txt', 'ASCII 栅格 (*.asc, *.txt)'}, ...
            '设置 HASM 结果文件', startPath);
        if isequal(name, 0)
            return;
        end
        S.outputFile = fullfile(folder, name);
        S.outputChosen = true;
        ok = true;
        setStatus(['结果将写入：' S.outputFile]);
    end

    function onOpenResult(~, ~)
        startPath = S.outputFile;
        if exist(startPath, 'file') ~= 2
            startPath = S.referenceFile;
        end
        selected = chooseFile(startPath, ...
            {'*.txt;*.asc', 'ASCII 栅格文件'; '*.*', '所有文件'}, ...
            '打开已有 HASM 结果');
        if isempty(selected)
            return;
        end
        try
            [g, meta] = HASM_ReadGrid(selected);
            validateGrid(g);
            S.resultGrid = g;
            S.resultMeta = meta;
            S.resultIsReference = true;
            S.resultSourceFile = selected;
            refreshButtons();
            setStatus(['已载入已有结果：' selected]);
        catch ME
            showError('打开结果失败', ME);
        end
    end

    function onRestoreDefaults(~, ~)
        onSelectExample('tree');
    end

    function onSelectExample(name)
        S.pointsFile = fullfile(dataDir, [name '.csv']);
        S.initialFile = fullfile(dataDir, [name '_initial.asc']);
        S.maskFile = fullfile(dataDir, [name '_mask.asc']);
        S.outputFile = fullfile(resultDir, [name '_hasm_run.asc']);
        S.referenceFile = fullfile(dataDir, [name '_hasm_reference.asc']);
        S.outputChosen = false;
        S.points = [];
        S.pointsLoadedFrom = '';
        set(S.table, 'Data', zeros(0, 3));
        S.resultGrid = [];
        S.resultMeta = struct();
        S.resultIsReference = false;
        S.resultSourceFile = '';
        restoreError = '';
        if exist(S.referenceFile, 'file') == 2
            try
                [S.resultGrid, S.resultMeta] = HASM_ReadGrid(S.referenceFile);
                validateGrid(S.resultGrid);
                S.resultIsReference = true;
                S.resultSourceFile = S.referenceFile;
            catch ME
                restoreError = ME.message;
            end
        end
        refreshButtons();
        if isempty(restoreError)
            setStatus(['已切换到 ' name '.csv 示例；可查看预计算结果或重新构建。']);
        else
            setStatus(['预置示例结果读取失败：' restoreError]);
        end
    end

    function onRaw2D(~, ~)
        if ~ensureFile('initial')
            return;
        end
        try
            [g, meta] = HASM_ReadGrid(S.initialFile);
            validateGrid(g);
            plotImage(g, meta, demoTitle('二维原始点云（初始栅格）', ...
                S.initialFile));
            setStatus('已显示初始栅格的二维点云图。');
        catch ME
            showError('二维点云显示失败', ME);
        end
    end

    function onRaw3D(~, ~)
        if ~ensurePoints()
            return;
        end
        try
            p = S.points;
            [h, ax] = makePlotFigure(demoTitle('三维原始点云', ...
                S.pointsFile));
            if size(p, 1) > 50000
                p = p(unique(round(linspace(1, size(p, 1), 50000))), :);
            end
            scatter3(ax, p(:, 1), p(:, 2), p(:, 3), 8, p(:, 3), ...
                'filled', 'MarkerEdgeColor', 'none');
            finish3DPlot(ax, p(:, 3));
            rotate3d(h, 'on');
            setStatus('已显示三维原始点云。');
        catch ME
            showError('三维点云显示失败', ME);
        end
    end

    function onDTM(~, ~)
        if ~ensureFile('initial')
            return;
        end
        try
            [g, meta] = HASM_ReadGrid(S.initialFile);
            validateGrid(g);
            [x, y, g] = gridForPlot(g, meta);
            [X, Y] = meshgrid(x, y);
            [h, ax] = makePlotFigure(demoTitle('三维初始高程表面（DTM）', ...
                S.initialFile));
            surf(ax, X, Y, g, g, 'EdgeColor', 'none', ...
                'FaceColor', 'interp');
            finish3DPlot(ax, g);
            rotate3d(h, 'on');
            setStatus('已显示初始栅格的三维高程表面。');
        catch ME
            showError('DTM 显示失败', ME);
        end
    end

    function onRun(~, ~)
        if S.busy || ~ensurePoints() || ~ensureFile('initial') || ...
                ~ensureFile('mask')
            return;
        end
        outputDir = fileparts(S.outputFile);
        try
            if exist(outputDir, 'dir') ~= 7
                mkdir(outputDir);
            end
            S.busy = true;
            refreshButtons();
            set(fig, 'Pointer', 'watch');
            setStatus('HASM 构建中，请稍候...');
            startTime = tic;
            [g, meta] = HASM_Run(S.pointsFile, S.initialFile, ...
                S.maskFile, S.outputFile);
            validateGrid(g);
            if exist(S.outputFile, 'file') ~= 2
                error('HASM_Run 未写出结果文件：%s', S.outputFile);
            end
            S.resultGrid = g;
            S.resultMeta = meta;
            S.resultIsReference = false;
            S.resultSourceFile = S.outputFile;
            S.busy = false;
            set(fig, 'Pointer', 'arrow');
            refreshButtons();
            setStatus(sprintf('HASM 构建完成（%.1f 秒），结果：%s', ...
                toc(startTime), S.outputFile));
        catch ME
            S.busy = false;
            if ishandle(fig)
                set(fig, 'Pointer', 'arrow');
                refreshButtons();
            end
            showError('HASM 构建失败', ME);
        end
    end

    function onResult2D(~, ~)
        if ~ensureResult()
            return;
        end
        try
            plotImage(S.resultGrid, S.resultMeta, ...
                resultTitle('二维 HASM 结果'));
            setResultStatus('已显示二维 HASM 结果');
        catch ME
            showError('二维结果显示失败', ME);
        end
    end

    function onMesh(~, ~)
        if ~ensureResult()
            return;
        end
        try
            [x, y, g] = gridForPlot(S.resultGrid, S.resultMeta);
            % Limit mesh density so the crown shape stays visible.
            step = max(1, ceil(max(size(g)) / 70));
            rows = unique([1:step:size(g, 1), size(g, 1)]);
            cols = unique([1:step:size(g, 2), size(g, 2)]);
            [X, Y] = meshgrid(x(cols), y(rows));
            z = g(rows, cols);
            [h, ax] = makePlotFigure(resultTitle('网格 HASM 点云模型'));
            mesh(ax, X, Y, z, z, 'FaceColor', 'none', ...
                'EdgeColor', 'interp', 'LineWidth', 0.7);
            finish3DPlot(ax, g);
            rotate3d(h, 'on');
            setResultStatus('已显示网格 HASM 模型');
        catch ME
            showError('网格模型显示失败', ME);
        end
    end

    function onSurface(~, ~)
        if ~ensureResult()
            return;
        end
        try
            [x, y, g] = gridForPlot(S.resultGrid, S.resultMeta);
            [X, Y] = meshgrid(x, y);
            [h, ax] = makePlotFigure(resultTitle('精细 HASM 点云模型'));
            if isDemoSource(S.pointsFile) && ...
                    isDemoSource(S.initialFile) && ...
                    isDemoSource(S.maskFile)
                % The two bundled masks are convex. Triangulating their
                % valid cell centers avoids serrated raster-edge faces.
                valid = isfinite(g);
                px = X(valid); py = Y(valid); pz = g(valid);
                tri = delaunay(px, py);
                % trisurf() in R2016b does not accept an axes handle as
                % its first argument, so plot into the current axes and
                % move the surface object into the panel afterwards.
                hs = trisurf(tri, px, py, pz, pz, ...
                    'EdgeColor', 'none', 'FaceColor', 'interp');
                set(hs, 'Parent', ax);
            else
                surf(ax, X, Y, g, g, 'EdgeColor', 'none', ...
                    'FaceColor', 'interp');
            end
            finish3DPlot(ax, g);
            rotate3d(h, 'on');
            setResultStatus('已显示精细 HASM 模型');
        catch ME
            showError('精细模型显示失败', ME);
        end
    end

    function plotImage(g, meta, plotTitle)
        [x, y, g] = gridForPlot(g, meta);
        [~, ax] = makePlotFigure(plotTitle);
        im = imagesc(ax, [x(1) x(end)], [y(1) y(end)], g);
        set(im, 'AlphaData', double(isfinite(g)));
        set(ax, 'YDir', 'normal', 'Color', [0.95 0.97 0.98]);
        axis(ax, 'image');
        axis(ax, 'tight');
        xlabel(ax, 'X 坐标');
        ylabel(ax, 'Y 坐标');
        colormap(ax, parula(256));
        setColorScale(ax, g);
        addElevationColorbar(ax);
    end

    function [x, y, g] = gridForPlot(g, meta)
        g = double(g);
        g(~isfinite(g) | g == -9999) = NaN;
        if isfield(meta, 'nodata') && ~isempty(meta.nodata)
            g(g == meta.nodata) = NaN;
        end
        if ~any(isfinite(g(:)))
            error('栅格中没有可显示的有效高程值。');
        end
        cellsize = meta.cellsize;
        x = meta.xllcorner + ((1:size(g, 2)) - 0.5) * cellsize;
        % ArcGIS ASCII rows are stored north-to-south.
        y = meta.yllcorner + ((size(g, 1):-1:1) - 0.5) * cellsize;
    end

    function [h, ax] = makePlotFigure(plotTitle)
        h = figure('Name', plotTitle, 'NumberTitle', 'off', ...
            'Color', 'w', 'Position', [110 80 960 680]);
        ax = axes('Parent', h, 'Position', [0.10 0.12 0.72 0.78], ...
            'FontSize', 10, 'LineWidth', 0.9, 'Box', 'on');
        % Preserve the title when imagesc/scatter3/surf creates its object.
        set(ax, 'NextPlot', 'add');
        title(ax, plotTitle, 'FontSize', 15, 'FontWeight', 'bold');
    end

    function finish3DPlot(ax, heights)
        xlabel(ax, 'X 坐标');
        ylabel(ax, 'Y 坐标');
        zlabel(ax, '高程');
        grid(ax, 'on');
        axis(ax, 'tight');
        daspect(ax, [1 1 0.8]);
        view(ax, -35, 28);
        colormap(ax, parula(256));
        setColorScale(ax, heights);
        addElevationColorbar(ax);
    end

    function setColorScale(ax, values)
        values = values(isfinite(values));
        low = min(values(:));
        high = max(values(:));
        if high <= low
            margin = max(0.05, abs(low) * 0.01);
            low = low - margin;
            high = high + margin;
        end
        caxis(ax, [low high]);
    end

    function addElevationColorbar(ax)
        cb = colorbar(ax);
        ylabel(cb, '高程');
    end

    function plotTitle = demoTitle(baseTitle, sourceFile)
        plotTitle = baseTitle;
        if isDemoSource(sourceFile)
            plotTitle = [baseTitle '（模拟示例）'];
        end
    end

    function plotTitle = resultTitle(baseTitle)
        plotTitle = baseTitle;
        if S.resultIsReference
            demo = isDemoSource(S.resultSourceFile);
        else
            demo = isDemoSource(S.pointsFile) && ...
                isDemoSource(S.initialFile);
        end
        if demo
            plotTitle = [baseTitle '（模拟示例）'];
        end
    end

    function yes = isDemoSource(sourceFile)
        demoNames = {'tree.csv', 'tree_initial.asc', 'tree_mask.asc', ...
            'tree_hasm_reference.asc', 'shrup.csv', 'shrup_initial.asc', ...
            'shrup_mask.asc', 'shrup_hasm_reference.asc'};
        yes = false;
        for k = 1:numel(demoNames)
            if strcmpi(sourceFile, fullfile(dataDir, demoNames{k}))
                yes = true;
                return;
            end
        end
    end

    function setResultStatus(prefix)
        if S.resultIsReference && isDemoSource(S.resultSourceFile)
            setStatus([prefix '（预计算的模拟示例）。']);
        elseif S.resultIsReference
            setStatus([prefix '（载入的已有结果）。']);
        else
            setStatus([prefix '（本次构建结果）。']);
        end
    end

    function ok = ensurePoints()
        ok = false;
        if ~isempty(S.points) && strcmp(S.pointsLoadedFrom, S.pointsFile)
            ok = true;
            return;
        end
        if ~ensureFile('points')
            return;
        end
        try
            loadPoints(S.pointsFile);
            ok = true;
        catch ME
            showError('读取点云失败', ME);
        end
    end

    function ok = ensureFile(kind)
        switch kind
            case 'points'
                path = S.pointsFile;
                filters = {'*.csv;*.txt;*.xyz;*.xls;*.xlsx', ...
                    '点云数据文件'; '*.*', '所有文件'};
                dialogTitle = '选择 XYZ 点云文件';
            case 'initial'
                path = S.initialFile;
                filters = {'*.txt;*.asc', 'ASCII 栅格文件'; '*.*', '所有文件'};
                dialogTitle = '选择 HASM 初始栅格';
            case 'mask'
                path = S.maskFile;
                filters = {'*.txt;*.asc', 'ASCII 栅格文件'; '*.*', '所有文件'};
                dialogTitle = '选择模拟区域掩膜栅格';
        end
        ok = exist(path, 'file') == 2;
        if ok
            return;
        end
        selected = chooseFile(path, filters, dialogTitle);
        if isempty(selected)
            return;
        end
        switch kind
            case 'points'
                S.pointsFile = selected;
            case 'initial'
                S.initialFile = selected;
                invalidateComputedResult();
            case 'mask'
                S.maskFile = selected;
                invalidateComputedResult();
        end
        ok = true;
    end

    function selected = chooseFile(defaultPath, filters, dialogTitle)
        selected = '';
        if exist(defaultPath, 'file') == 2
            startPath = defaultPath;
        elseif exist(fileparts(defaultPath), 'dir') == 7
            startPath = fileparts(defaultPath);
        else
            startPath = appDir;
        end
        [name, folder] = uigetfile(filters, dialogTitle, startPath);
        if ~isequal(name, 0)
            selected = fullfile(folder, name);
        end
    end

    function invalidateComputedResult()
        if ~S.resultIsReference
            S.resultGrid = [];
            S.resultMeta = struct();
            S.resultSourceFile = '';
        end
        refreshButtons();
    end

    function ok = ensureResult()
        ok = ~isempty(S.resultGrid);
        if ~ok
            errordlg('请先点击“点击进行HASM构建”，或从“文件”菜单打开已有结果。', ...
                '尚无 HASM 结果', 'modal');
        end
    end

    function validateGrid(g)
        if ~isnumeric(g) || ~isreal(g) || isempty(g) || ndims(g) ~= 2
            error('栅格必须为非空二维数值矩阵。');
        end
    end

    function showError(titleText, ME)
        setStatus([titleText '：' ME.message]);
        errordlg(ME.message, titleText, 'modal');
    end

    function onHelp(~, ~)
        msg = sprintf(['1. 点击“读取原始点云xyz数据”选择 XYZ 文件。\n' ...
            '2. 可在“文件”菜单修改初始栅格、掩膜栅格和输出文件。\n' ...
            '3. 查看原始点云，并点击“HASM构建”。\n' ...
            '4. 构建完成后查看二维、网格和精细模型。\n\n' ...
            '通过“示例”菜单切换 tree.csv 与 shrup.csv；结果图会标明模拟示例。']);
        msgbox(msg, '使用步骤', 'help', 'modal');
    end

    function onClose(~, ~)
        if S.busy
            warndlg('HASM 正在构建，请完成后再关闭窗口。', '构建中', 'modal');
            return;
        end
        delete(fig);
    end
end
