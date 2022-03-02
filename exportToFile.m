function exportToFile(TT,out_filename,out_variable_name,varargin)
% exportToFile(TT,out_filename,out_variable_name,varargin)
% 
%   Export (sessioned) timetable data to a CSV and/or .mat-file
%
%   In:
%       TT                  Timetable or cell array of timetables
%       out_filename        Name of the output CSV file and .mat-file
%       out_variable_name   Name of variable which will be written in a .mat-file
%       varargin            Optional parameter/value list:
%                               - 'SaveTo'        {'mat','csv','both'}
%                                   * Target file format (default: both)
%                           - 'ChunkSize'
%                               * Size of file chunks that are generated 
%                                 in MB
%                           - 'NumFiles'
%                               * Instead of a chunk size a fixed number
%                                 of output files can be defined
%                               - 'StartTime' format: uuuu-MM-dd HH:mm:ss
%                                   * Only save data after 'StartTime'
%                               - 'EndTime' format: uuuu-MM-dd HH:mm:ss
%                                   * Only save data after 'StartTime'
% 
%   Other m-files required:
%           - writeToMatFile
%           - writeToCsvFile
%           - limitTt
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: none

%   Author: Hanno Winter
%   Date: 26-Nov-2019; Last revision: 23-Apr-2020

%% Init and Checks

p = getParser();
p.parse(varargin{:});
parse_result = p.Results;
save_target = parse_result.SaveTo;
chunk_size = parse_result.ChunkSize;
num_files = parse_result.NumFiles;
start_time = parse_result.StartTime;
end_time = parse_result.EndTime;

if ~iscell(TT)
    TT = {TT};
end % if

if min(size(TT)) ~= 1
    error('exportToFile: Wrong dimension of ''TT''!');
end % if

%% Export Data to CSV

num_sessions = length(TT);     
for session_i = 1:num_sessions

    % Unfold 'TT' _________________________________________________________
    if ~isempty(TT{session_i})
        TT_session_i = TT{session_i};         
        out_variable_name_i = out_variable_name;
        csv_filenames = {};
    else
        continue
    end % if
    
    % Limit data __________________________________________________________
    if ~isempty(start_time) || ~isempty(end_time)
        TT_session_i = limitTt(TT_session_i,start_time,end_time);
    end % if
    
    % Possibly add session information to filename ________________________
    if isempty(regexp(out_filename,'[Ss]ession(\d{2})','tokens','once')) % no session information in filename
        out_filename_i = [out_filename,'_session',sprintf('%02i',session_i)];
    else % it is assumed that session information is already available in the filename
        out_filename_i = out_filename;
    end % if
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Export to CSV file 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ismember(save_target,{'csv','both',''})
    
        % Prepare input data ______________________________________________

        file_data = timetable2table(TT_session_i);
        file_data.Time = seconds(file_data.Time);

        table_datatypes = varfun(@class,file_data,'OutputFormat','cell');
        n_columns = size(file_data,2);
        
        header_names = [ ... 
                         sprintf('%s,','TimeUnix_s'), ... 
                         sprintf('%s,',string(TT_session_i.Properties.VariableNames(1,1:end-1))), ... 
                         sprintf('%s',string(TT_session_i.Properties.VariableNames(1,end))) ...
                       ];

        % Prepare output data _____________________________________________

        data_format = '';
        write_file_data = [];
        for column_i = 1:n_columns    

            switch table_datatypes{column_i}

                    case 'double'

                        data_format = [data_format,'%.16f,'];
                        write_file_data = [write_file_data, file_data{:,column_i}];

                    case 'logical'

                        data_format = [data_format,'%1i,'];
                        write_file_data = [write_file_data, double(file_data{:,column_i})];

                    case {'datetime','cell','categorical'}                

                        char_data = char(file_data{:,column_i});

                        write_file_data = [write_file_data, double(char_data)];
                        data_format = [data_format,[repmat('%c',1,size(char_data,2)),',']];              

                otherwise
                    error('exportToFile: Unsupported data type!');

            end % switch

        end % for column_i
        data_format = [data_format(1:end-1),'\r\n'];

        % Save to CSV file ________________________________________________
        csv_filenames = writeToCsvFile(write_file_data,data_format,header_names,out_filename_i,'ChunkSize',chunk_size,'NumFiles',num_files);
    
    end % if
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Export to .mat file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ismember(save_target,{'mat','both',''})
        if ~isempty(csv_filenames) % use the same number of files for .mat files, if data has already been stored to CSV files     
            writeToMatFile(TT_session_i,out_filename_i,out_variable_name_i,'NumFiles',length(csv_filenames));
        else
            writeToMatFile(TT_session_i,out_filename_i,out_variable_name_i,'ChunkSize',chunk_size,'NumFiles',num_files);
        end % if
    end % if
    
end % for session_i

clear TT_session_i

end % function

%% Helper Functions

function p = getParser()
    persistent parser
    if isempty(parser)
        parser = inputParser();
        parser.KeepUnmatched = true;
        parser.addParameter('SaveTo','');
        parser.addParameter('ChunkSize',[]);
        parser.addParameter('NumFiles',[]);
        parser.addParameter('StartTime','');
        parser.addParameter('EndTime','');
    end   
    
    p = parser;
end
