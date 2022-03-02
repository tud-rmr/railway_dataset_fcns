function filenames = writeToCsvFile(data,data_format,header_names,filename,varargin)
%  filenames = writeToCsvFile(data,data_format,header_names,filename,varargin)
% 
%   Write data to CSV file. The data can be stored in small file chunks.
%
%   In:
%       data            Data as double array
%       data_format     Format specs for each column of 'data'
%       header_names    Coulmn names
%       filename        Name of the output CSV file
%       varargin        Optional parameter/value list:
%                           - 'ChunkSize'
%                               * Size of file chunks that are generated 
%                                 in MB
%                           - 'NumFiles'
%                               * Instead of a chunk size a fixed number
%                                 of output files can be defined
%
%   Out:
%       filenames       Cell-array list of successfully written CSV files
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
    estimated_file_size = (numel(data)+numel(header_names))*15 / 1e6; % it is roughly assumed that each value needs 15 bytes storage space
    num_of_fileparts = ceil(estimated_file_size/chunk_size);
else
    num_of_fileparts = 1;
end % if
data_chunk_length = ceil(size(data,1)/num_of_fileparts);

filenames = {};

%% Calculations

fprintf(['Saving ''',filename,''' to CSV files...'])

for part_i = 1:num_of_fileparts        
           
    if num_of_fileparts > 1
        if part_i == 1
            fprintf('\n')
        end % if
        fprintf('\t Part %i/%i...',part_i,num_of_fileparts)
        
        filename_i = [filename,'_part',sprintf('%02i',part_i),'.csv'];
    else
        filename_i = [filename,'.csv'];
    end % if
    data_indices_i = 1:min(data_chunk_length,size(data,1));
    
    % Write to file with NaNs
    fileID = fopen(filename_i,'w');
    fprintf(fileID,'%s\r\n',header_names);
    fprintf(fileID,data_format,data(data_indices_i,:)');
    fclose(fileID);
            
    % Open file and remove NaNs
    if true
      fileID = fopen(filename_i,'r');  
      X = fread(fileID);
      fclose(fileID);

      X = char(X.');
      Y = strrep(X,'NaN','');

      fileID = fopen(filename_i,'w');  
      fwrite(fileID,Y);
      fclose(fileID);
    end
    
    data = data(data_chunk_length+1:end,:);
    filenames{part_i,1} = filename_i;
    
    if num_of_fileparts > 1
        fprintf('done!\n')
    end % if
    
end % for i

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