function fileList = find_all_files(folder, filePattern, VerbosityLevel)


if ~exist('VerbosityLevel', 'var')
    VerbosityLevel = 1;
end



% Get list of all subfolders.
allSubFolders = genpath(folder);
% Parse into a cell array.
remain = allSubFolders;
folderNameList = {};
while true
    [singleSubFolder, remain] = strtok(remain, pathsep); % or use pathsep
    if isempty(singleSubFolder)
        break;
    end
    folderNameList = [folderNameList singleSubFolder];
end
nFolder = length(folderNameList);

fileList = {};
% Process all files in those folders.
for iFolder = 1:nFolder
    % Get this folder and print it out.
    thisFolder = folderNameList{iFolder};
    if (VerbosityLevel)
        fprintf('Processing folder %s\n', thisFolder);
    end
    
    % Get ALL files.
    currentPattern = [thisFolder, filesep, filePattern];
    baseFileNames = dir(currentPattern);
    nFile = length(baseFileNames);
    if nFile >= 1
        % Go through all those files.
        for iFile = 1:nFile
            fullFileName = fullfile(thisFolder, baseFileNames(iFile).name);
            if (VerbosityLevel)
                fprintf('     Processing file %s\n', fullFileName);
            end
            fileList = [fileList fullFileName];
        end
    else
        if (VerbosityLevel)           
            fprintf('     Folder %s has no files in it.\n', thisFolder);
        end
    end
end
end
