function build_exe()
%BUILD_EXE Build the Windows GUI executable with MATLAB Compiler R2016b.
root = fileparts(mfilename('fullpath'));
if exist(fullfile(root,'HASM_App.m'),'file') ~= 2
    error('HASM:Build','HASM_App.m is missing from the project folder.');
end
if license('test','Compiler') ~= 1
    error('HASM:Build','MATLAB Compiler license is unavailable.');
end
oldDir = pwd;
cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(root);
outputDir = fullfile(root,'dist');
if exist(outputDir,'dir') ~= 7
    mkdir(outputDir);
end
mcc('-e','-o','HASM_App','-d',outputDir,'HASM_App.m','-a','data');
if exist(fullfile(outputDir,'HASM_App.exe'),'file') ~= 2
    error('HASM:Build','Compiler finished without producing HASM_App.exe.');
end
disp(fullfile(outputDir,'HASM_App.exe'));
end
