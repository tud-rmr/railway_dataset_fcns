function [output_data, num_files, load_flag] = importFromFile(file_paths,output_filename,varargin)
% [output_data, num_files, load_flag] = importFromFile(file_paths,output_filename,varargin)
%
%   Imports data from a CSV or .mat file, repsectively, and returns it. 
%
%   In:
%       file_paths          Cell array of paths to the files that should be 
%                           loaded
%       output_filename     Name of the output .mat-file
%       varargin            Optional parameter/value list:
%                               - 'DataType'        {'parameters','map','raw','processed','reference'}
%                                   * Type of the data being imported
%                               - 'SpecialVarTypes' {'varname1','type1';'varname2','type2';}
%                                   * see: setvartype
%                               - 'StartTime' format: uuuu-MM-dd HH:mm:ss
%                                   * Only load data after 'StartTime'
%                               - 'EndTime' format: uuuu-MM-dd HH:mm:ss
%                                   * Only load data before 'EndTime'
%
%   Out:
%       output_data         Loaded data as table or cell array of tables
%       num_files           Number of files provided for each session
%       load_flag           0 = failure, no data loaded
%                           1 = success, data loaded from CSV file
%                           2 = success, data loaded from .mat file (corresponding to 'output_filename')
%                           3 = success, data loaded from .mat file (corresponding to 'file_paths')
%                   
% 
%   Other m-files required: limitTt
%   Subfunctions: 
%       - existMatFile
%       - readPartedTable
%   MAT-files required: none
%
%   See also: setvartype

%   Author: Hanno Winter
%   Date: 13-Feb-2020; Last revision: 24-Nov-2020

%% Init and check

p = getParser();
p.parse(varargin{:});
parse_result = p.Results;
data_type = parse_result.DataType;
special_var_types = parse_result.SpecialVarTypes;
start_time = parse_result.StartTime;
end_time = parse_result.EndTime;

input_sessions = regexp(file_paths,'[Ss]ession(\d{2})','tokens','once');
input_sessions = str2double([input_sessions{:}]);

%% Report

fprintf('\n### Import from file ###\n')
fprintf('Data Type: %s\n',data_type)
if ~isempty(special_var_types)
    fprintf('Special Variable Types: true\n')
else
    fprintf('Special Variable Types: false\n')
end % if
if ~isempty(start_time)
    fprintf('Start Time: %s\n',start_time)
else
    fprintf('Start Time: []\n')
end % if
if ~isempty(end_time)
    fprintf('End Time: %s\n',end_time)
else
    fprintf('End Time: []\n')
end % if
% fprintf('\n');

%% Calculations

% Init ____________________________________________________________________

if ~isempty(input_sessions)
    output_data(1:max(input_sessions),1) = {table()};    
    load_flag(1:max(input_sessions),1) = 0;
    num_files(1:max(input_sessions),1) = 0;
    
%     unique_session_numbers = unique(input_sessions);
%     num_files = zeros(length(unique_session_numbers),1);
%     for i = 1:length(unique_session_numbers)
%         num_files(i) = sum(input_sessions==unique_session_numbers(i));
%     end % for i
else
    output_data(1:length(file_paths),1) = {table()};
    num_files(1:length(file_paths),1) = 1;
    load_flag(1:length(file_paths),1) = 0;
end % if

loaded_files = {};

% Import __________________________________________________________________

for path_i = 1:length(file_paths)    
    
    if ~isempty(input_sessions)
        session_i = input_sessions(path_i);
    else
        session_i = path_i;
    end % if    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1/2) Load data from .mat file if it already exists
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Load available .mat files and skip CSV import _______________________
    [mat_file,mat_file_load_type] = existMatFile(file_paths{path_i},output_filename);
    if ~isempty(mat_file) && any(ismember(mat_file,loaded_files))
        continue
    end % if
    
    if ~isempty(mat_file)        
             
        fprintf(['Loading data from ''',mat_file,'''...']);

        variable_str = whos('-file',mat_file);
        variable_str = variable_str.name;                    

        output_data_part = load(mat_file,variable_str);
        data_tmp = output_data_part.(variable_str);                      

        if istimetable(data_tmp) && ~istimetable(output_data{session_i,1}) && isempty(output_data{session_i,1})
            output_data{session_i,1} = timetable();                
        elseif istimetable(data_tmp) && ~istimetable(output_data{session_i,1}) && ~isempty(output_data{session_i,1})
            data_tmp = timetable2table(data_tmp);
        end % if  
        
        output_data{session_i,1} = [output_data{session_i,1};data_tmp];
        num_files(session_i,1) =  num_files(session_i,1) + 1;
        load_flag(session_i,1) = mat_file_load_type;
        
        loaded_files = [loaded_files;mat_file];
        
        clear output_data_part_i data_tmp_i
        
        fprintf('done!\n');

        continue
        
    end % if
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2/2) Load data from CSV file if it is available
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Prepare import ______________________________________________________
        
    [~,filename_i,ext_i] = fileparts(file_paths{path_i});
    input_file_i = [filename_i,ext_i];
    
    if ~isempty(input_file_i) && any(ismember(input_file_i,loaded_files))
        continue
    end % if
    
    if ~exist(file_paths{path_i},'file') 
        error(['importFromFile: Input file ''',input_file_i,''' not available on path!']);
    end % if      
    
    opts_i = detectImportOptions(file_paths{path_i},'EmptyColumnType','double');
    if ~isempty(special_var_types)
        opts_i = setvartype(opts_i,special_var_types(:,1),special_var_types(:,2));
    end % if 

    % Start import ________________________________________________________
    
    switch data_type

        case {'processed','reference'}

            fprintf(['Importing ',data_type,' data from ''',input_file_i,'''...']);                                  
            output_data{session_i,1} = readPartedTable(output_data{session_i,1},file_paths{path_i},opts_i);            
            if ~istimetable(output_data{session_i,1})
                output_data{session_i,1} = table2timetable(output_data{session_i,1}(:,2:end),'RowTimes',seconds(output_data{session_i,1}.TimeUnix_s));
            end % if            
            fprintf('done!\n');

        case {'raw'}

            fprintf(['Importing ',data_type,' data from ''',input_file_i,'''...']);
            output_data{session_i,1} = readPartedTable(output_data{session_i,1},file_paths{path_i},opts_i);
            fprintf('done!\n');

        case {'parameters'}

            fprintf(['Importing ',data_type,' data from ''',input_file_i,'''...']);
            output_data{session_i,1} = readtable(file_paths{path_i},opts_i);
            fprintf('done!\n');

         case {'map'}

            fprintf(['Importing ',data_type,' data from ''',input_file_i,'''...']);
            output_data{session_i,1} = readtable(file_paths{path_i},opts_i);
            fprintf('done!\n');

        otherwise

            fprintf(['Importing ''',input_file_i,''' data...']);           
            output_data{session_i,1} = readPartedTable(output_data{path_i,1},file_paths{path_i},opts_i);
            fprintf('done!\n');

    end % switch
    
    load_flag(session_i,1) = 1;
    num_files(session_i,1) =  num_files(session_i,1) + 1;
    
    loaded_files = [loaded_files;input_file_i];
    
end % for path_i

%% Post-Processing

% Apply time limits _______________________________________________________
for session_i = 1:size(output_data,1)
    if istimetable(output_data{session_i,1}) && ( ~isempty(start_time) || ~isempty(end_time) )
        output_data{session_i,1} = limitTt(output_data{session_i,1},start_time,end_time);
    end % if
end % for session_i

% Unwrap none session based data if it comes from a single file ___________
if isempty(input_sessions) && length(output_data) == 1
    output_data = output_data{1,1};
end % if

end % function

%% Helper Functions

function p = getParser()
    persistent parser
    if isempty(parser)
        parser = inputParser();
        parser.KeepUnmatched = true;
        parser.addParameter('DataType','');
        parser.addParameter('SpecialVarTypes',{});
        parser.addParameter('StartTime','');
        parser.addParameter('EndTime','');
    end   
    
    p = parser;
end

function [mat_file,load_type] = existMatFile(input_file_path,output_filename)
% mat_file = existMatFile(input_file_path)
%
%   Checks for .mat file corresponding to 'input_file_path'
%
%   In:
%       input_file_path     Path to CSV file
%       output_filename     Name of the output .mat-file passed to parent 
%                           function 'importFromFile' 
%
%   Out:
%       mat_file            Path to corresponding .mat files
%       load_type           2: Direct load from specified 'output_filename'
%                           3: Indirect load from 'input_file_path'
%                   
% 
%   Other m-files required: none
%   Subfunctions: none
%   MAT-files required: none
%
%   See also:

%   Author: Hanno Winter
%   Date: 23-Apr-2020; Last revision: 24-Nov-2020

mat_file = [];
load_type = [];

% Check for single .mat file with 'output_filename'
if exist([output_filename,'.mat'],'file')
    mat_file = [output_filename,'.mat'];
    load_type = 2;
    return
end % if

% Check for session data
input_session = regexp(input_file_path,'[Ss]ession(\d{2})','tokens','once');
input_session = str2double(unique([input_session{:}]));
part = regexp(input_file_path,'_part(\d{2})','tokens','once');

if ~isempty(input_session)
    
    % Single session file
    session_mat_filename = ... 
        [output_filename,'_session',sprintf('%02i',input_session),'.mat'];    
    if exist(session_mat_filename,'file')
        mat_file = session_mat_filename;
        load_type = 2;
        return
    end % if
    
    % Parted session file
    if ~isempty(part)
        part = str2double(part{:});       
        session_parted_mat_filename = @(part_i) ... 
            [output_filename,'_session',sprintf('%02i',input_session),'_part',sprintf('%02i',part_i),'.mat'];
        
        if exist(session_parted_mat_filename(part),'file')
            mat_file = session_parted_mat_filename(part);
            load_type = 2;
            return
        end % if
    end % if
    
%     % Parted session file
%     session_parted_mat_filename = @(part_i) ... 
%         [output_filename,'_session',sprintf('%02i',input_session),'_part',sprintf('%02i',part_i),'.mat'];
% 
%     part_i = 1;
%     while exist(session_parted_mat_filename(part_i),'file')
%         mat_files{end+1,1} = session_parted_mat_filename(part_i);
%         part_i = part_i + 1;
%     end % while
    
end % if

% Check for single .mat file with 'input_filename'
[~,input_filename,~] = fileparts(input_file_path);
single_mat_filename = [input_filename,'.mat'];
if exist(single_mat_filename,'file')
    mat_file = single_mat_filename;
    load_type = 3;
    return
end % if

end % function

function output_data = readPartedTable(data,file_paths,opts)
% output_data = readPartedTable(data,file_paths,opts)
%
%   Calls 'readtable' and appends data to 'data.
%
%   In:
%       data            Variable the loaded data should be appended to
%       file_paths      Paths to the file that should be loaded
%       opts            Options for 'readtable'
%
%   Out:
%       output_data     Loaded data as table or timetable
%                   
% 
%   Other m-files required: none
%   Subfunctions: none
%   MAT-files required: none
%
%   See also:

%   Author: Hanno Winter
%   Date: 23Apr-2020; Last revision: 23-Apr-2020

data_tmp = readtable(file_paths,opts);

if istimetable(data)
    data_tmp = table2timetable(data_tmp(:,2:end),'RowTimes',seconds(data_tmp.TimeUnix_s));
end % if

if ~isempty(data)
    output_data = [data;data_tmp];
else
    output_data = data_tmp;
end % if

end % function
