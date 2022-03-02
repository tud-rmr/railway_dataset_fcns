function [error_ellipse_sep,error_ellipse_cmb] = getLatLonErrorEllipsePoints(pos,major,minor,alpha,resolution)
% error_ellipse = getLatLonErrorEllipsePoints(pos,major,minor,alpha,resolution)
% 
%   Plot error ellipse
%
%   In:
%       pos         (latitude,longitude)-positions of error-ellipse center as (2 x n)-matrix
%       major       error ellipse semi-major axis as array 
%       minor       error ellipse semi-minor axis as array
%       alpha       error ellipse orientation in degree as array
%       resolution  optional: number of points being used to plot the error
%                             ellipse
% 
%   Out:
%       error_ellipse_sep   separated (latitude,longitude)-points of the 
%                           error ellipses as (2 x resolution x n)-matrix
%       error_ellipse_cmb   combined (latitude,longitude)-points of the 
%                           error ellipses as single matrix separated by 
%                           NaN (this data can be plotted easily)
%
%   Other m-files required: 
%       * getXyErrorEllipsePoints
%       * ll2umt
%       * utm2ll
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: none

%   Author: Hanno Winter
%   Date: 14-May-2020; Last revision: 14-May-2020
%

%% Init

if nargin < 5
    resolution = 360;
end % if

if size(pos,1) ~= 2
    error('getLatLonErrorEllipsePoints: ''pos'' has wrong dimension!');
end % if

%% Calculations

[x,y,f] = ll2utm(pos(1,:),pos(2,:));
pos_utm = [x(:)';y(:)'];

[err_ellipse_utm_sep,~] = getXyErrorEllipsePoints( ... 
                                                   pos_utm, ... 
                                                   major, ... 
                                                   minor, ... 
                                                   90-alpha, ... 
                                                   resolution ... 
                                                 );

error_ellipse_sep = nan(size(err_ellipse_utm_sep));
error_ellipse_cmb = nan(2,size(err_ellipse_utm_sep,2)+1,size(err_ellipse_utm_sep,3));
for i = 1:size(err_ellipse_utm_sep,3)
    [error_ellipse_sep(1,:,i),error_ellipse_sep(2,:,i)] = ... 
        utm2ll(err_ellipse_utm_sep(1,:,i),err_ellipse_utm_sep(2,:,i),f(min(length(f),i)),'wgs84');
    error_ellipse_cmb(1:2,1:end-1,i) = error_ellipse_sep(1:2,:,i);
end % for i
error_ellipse_cmb = reshape(error_ellipse_cmb,2,size(error_ellipse_cmb,2)*size(error_ellipse_cmb,3));

end % function
