function new_tt = limitTt(TT,start_time,end_time)
% new_tt = limitTt(TT,start_time,end_time)
%
%   Limit timetable data to a specific start and end time.
% 
%   In:
%       TT          Timetable
%       start_time  New start time (as number or string according to 'uuuu-MM-dd HH:mm:ss')
%       end_time    New end time (as number or string according to 'uuuu-MM-dd HH:mm:ss')
%
%   Out:
%       new_tt      Timetable limited to 'start_time' and 'end_time'
%
%   Other m-files required: none
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: datetime

%   Author: Hanno Winter
%   Date: 26-Nov-2019; Last revision: 24-Nov-2020

%% Init and check

if isempty(start_time) && ~isempty(end_time)
    new_tt = TT;
    return
end

% Check start time ________________________________________________________

if ~isempty(start_time) && ischar(start_time)
    
    start_time = datetime(start_time,'InputFormat','uuuu-MM-dd HH:mm:ss');
    start_time.TimeZone = 'utc';
    start_time = posixtime(start_time);
    
elseif ~isempty(start_time) && isduration(start_time)
    
    start_time = seconds(start_time);
    
elseif isempty(start_time) || isnumeric(start_time)
    
    % nothing to do
    
else
    
    error('limitTt: No valid time format passed for ''start_time''!');
    
end % if

% Check end time __________________________________________________________

if ~isempty(end_time) && ischar(end_time)
    
    end_time = datetime(end_time,'InputFormat','uuuu-MM-dd HH:mm:ss');
    end_time.TimeZone = 'utc';
    end_time = posixtime(end_time);
    
elseif ~isempty(end_time) && isduration(end_time)
    
    end_time = seconds(end_time);
    
elseif isempty(end_time) || isnumeric(end_time)
    
    % nothing to do
    
else
    
    error('limitTt: No valid time format passed for ''end_time''!');
    
end % if
    
%% Calculations    

% Find start time index ___________________________________________________

if ~isempty(start_time) && start_time>=seconds(TT.Time(1)) && start_time<=seconds(TT.Time(end))
    new_t1_index = find(seconds(TT.Time)>start_time,1,'first')-1;
elseif ~isempty(start_time) && start_time<seconds(TT.Time(1))
    new_t1_index = 1;
elseif ~isempty(start_time) && start_time>seconds(TT.Time(end))
    new_t1_index = 0;
else
    new_t1_index = 1;
end % if

% Find end time index _____________________________________________________

if ~isempty(end_time) && end_time>=seconds(TT.Time(1)) && end_time<=seconds(TT.Time(end))
    new_tend_index = find(seconds(TT.Time)<end_time,1,'last')+1;
elseif ~isempty(end_time) && end_time<seconds(TT.Time(1))
    new_tend_index = 0;
elseif ~isempty(end_time) && end_time>seconds(TT.Time(end))
    new_tend_index = length(seconds(TT.Time));
else
    new_tend_index = length(seconds(TT.Time));
end % if

% Limit timetable or write empty timetable ________________________________

if all([new_t1_index,new_tend_index])  
    
    new_tt = TT(new_t1_index:new_tend_index,:);
    
else
    
    if ~isempty(TT) && diff(TT.Time([1 end]))>0
        warning('limitTt: Wrote empty timetable! At least one of the time limits seems to be out of range!');
    end % if
    
%     new_tt = timetable();
    new_tt = TT(1,:);
    for i = 1:size(new_tt,2)
        if isnumeric(new_tt{1,i})
            new_tt{1,i} = nan;
        end % if
    end % for i
    new_tt.Time = duration(seconds(0));
    
end % if
    
end % function