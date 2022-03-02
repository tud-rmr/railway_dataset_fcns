function filenames = writeToMatFile(data,filename,variable_name,varargin)
%  filenames = writeToMatFile(data,filename,variable_name,varargin)
% 
%   Write data to .mat file. The data can be stored in small file chunks.
%
%   In:
%       data            Data as timetable
%       filename        Name of the output .mat file
%       variable_name   Name of variable which will be written in a .mat-file
%       varargin        Optional parameter/value list:
%                           - 'ChunkSize'
%                               * Size of file chunks that are generated 
%                                 in MB
%                           - 'NumFiles'
%                               * Instead of a chunk size a fixed number
%                                 of output files can be defined
%
%   Out:
%       filenames       Cell-array list of successfully written .mat files
% 
%   Other m-files required: none
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: none

%   Author: Hanno Winter
%   Date: 20-Apr-2020; Last revision: 12-Nov-2020

%% Init

p = getParser();
p.parse(varargin{:});
parse_result = p.Results;
chunk_size = parse_result.ChunkSize;
num_files = parse_result.NumFiles;

if ~isempty(num_files)
    num_of_fileparts = num_files;
elseif ~isempty(chunk_size)
    estimated_file_size = numel(data)*3 / 1e6; % it is roughly assumed that each value needs 3 bytes storage space
    num_of_fileparts = ceil(estimated_file_size/chunk_size);
else
    num_of_fileparts = 1;
end % if
data_chunk_length = ceil(size(data,1)/num_of_fileparts);

filenames = {};

%% Calculations

fprintf(['Saving ''',filename,''' to .mat files...'])

for part_i = 1:num_of_fileparts
       
    % Create data chunk
    data_indices_i = 1:min(data_chunk_length,size(data,1));
    data_i = data(data_indices_i,:);
    
    % Check for size limitations of build-in 'save' function
    whos_data_i = whos('data_i');
    size_data_i = whos_data_i.bytes;
    max_variable_size = 1.9e9;
    if size_data_i > max_variable_size
        
        warning('writeToMatFile: Changed chunk size because ''save'' can only handle variables up to 2GB!');
        
        new_num_files = ceil(size_data_i/max_variable_size * num_of_fileparts);
        filenames = writeToMatFile(data,filename,variable_name,'NumFiles',new_num_files);  
        
        return
    end % if
    
    % Output preparations
    if num_of_fileparts > 1
        if part_i == 1
            fprintf('\n')
        end % if
        fprintf('\t Part %i/%i...',part_i,num_of_fileparts)
        
        filename_i = [filename,'_part',sprintf('%02i',part_i)];
        variable_name_i = [variable_name,'_part',sprintf('%02i',part_i)];
    else        
        filename_i = filename;
        variable_name_i = variable_name;
    end % if    
            
    % Write to file  
    data_tmp_struct.(variable_name_i) = data_i;
    save(filename_i,'-struct','data_tmp_struct')
    clear data_tmp_struct    
        
    data = data(data_chunk_length+1:end,:);
    filenames{part_i,1} = filename_i;
    
    if num_of_fileparts > 1
        fprintf('done!\n')
    end % if    
    
end % for part_i

fprintf('done!\n')

end % function

%% Helper Functions

function p = getParser()
    persistent parser
    if isempty(parser)
        parser = inputParser();
        parser.KeepUnmatched = true;
        parser.addParameter('ChunkSize',[]);
        parser.addParameter('NumFiles',[]);
    end   
    
    p = parser;
end