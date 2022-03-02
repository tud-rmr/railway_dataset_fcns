function setDatasetPaths()
% setDatasetPaths()
% 
%   Automatically add all folders of the dataset at hand to the Matlab path.
%
%   In:     
%           none
%
%   Out:    
%           none
% 
%   Other m-files required: none
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: none

%   Author: Hanno Winter
%   Date: 27-Feb-2020; Last revision: 13-May-2020

%% Settings

parameters_folder_name = '_parameters';
scripts_folder_name = '_scripts';
maps_folder_name = '_maps';
desc_folder_name = '_description';
data_folders_pattern = '(.*_[Ss]ession\d{2})'; % regular expression

%% Init

saved_pwd = pwd;

function_name = mfilename;
function_fullfile_path = which(function_name);
[filepath,~,~] = fileparts(function_fullfile_path);

%% Main

cd(filepath);
for i = 1:length(strfind(filepath,filesep))
    if exist(scripts_folder_name,'dir') && ... 
       exist(parameters_folder_name,'dir') && ... 
       exist(desc_folder_name,'dir')
        break
    else
        cd('..');
    end % if
end % for i

% Find data folders _______________________________________________________

dir_content = dir;
dir_content = {dir_content([dir_content.isdir],:).name};

data_folders_selector = regexp(dir_content,data_folders_pattern,'match');
data_folders_selector = cellfun(@(cell) ~isempty(cell),data_folders_selector);
data_folders = dir_content(data_folders_selector);

% Add folders to path _____________________________________________________

added_flag = false(4,1);
added_flag_tmp = false(length(data_folders),1);
for i = 1:length(data_folders)
    added_flag_tmp(i) = addToPathWithCheck(fullfile([pwd,filesep,data_folders{i}]));
end % for i

added_flag(1) = all(added_flag_tmp);
added_flag(2) = addToPathWithCheck(fullfile([pwd,filesep,parameters_folder_name]));
added_flag(3) = addToPathWithCheck(fullfile([pwd,filesep,scripts_folder_name]));
added_flag(4) = addToPathWithCheck(fullfile([pwd,filesep,maps_folder_name]));

%% Finish

cd(saved_pwd);

if any(added_flag)
    fprintf('\nSuccessfully added all necessary folders of this dataset to the Matlab path.\n\n')
end % if

end

%% Helper functions

function added_flag = addToPathWithCheck(folder_path)
% added_flag = addToPathWithCheck(folder_path)
% 
%   Add folder and subfolders to path, if it is not already on it.
%
%   In:
%       folder_path     full path to folder being added
%
%   Out:    
%       added_flag      true, if folder has been added, false otherwise  
% 
%   Other m-files required: none
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: none

%   Author: Hanno Winter
%   Date: 27-Feb-2020; Last revision: 27-Feb-2020

%%

if ispc
    folder_on_path = ~isempty(regexpi(path,folder_path,'once'));
else
    folder_on_path = ~isempty(regexp(path,folder_path,'once'));
end % if

if ~folder_on_path
    addpath(genpath(folder_path));
    added_flag = true;
else
    added_flag = false;
end % if

end % function

