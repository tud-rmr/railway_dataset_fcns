function [error_ellipse_sep,error_ellipse_cmb] = getXyErrorEllipsePoints(pos,major,minor,alpha,resolution)
% [error_ellipse] = getXyErrorEllipsePoints(pos,major,minor,alpha,resolution)
% 
%   Get (x,y)-points of error ellipse
%
%   In:
%       pos         positions of error-ellipse center as (2 x n)-matrix
%       major       error ellipse semi-major axis as array 
%       minor       error ellipse semi-minor axis as array
%       alpha       error ellipse orientation in degree as array
%       resolution  optional: number of points being used to plot the error
%                             ellipse
% 
%   Out:
%       error_ellipse_sep   separated (X,Y)-points of the 
%                           error ellipses as (2 x resolution x n)-matrix
%       error_ellipse_cmb   combined (X,Y)-points of the 
%                           error ellipses as single matrix separated by 
%                           NaN (this data can be plotted easily)
%
%   Other m-files required: calcErrorEllipseParameters
%   Subfunctions: none
%   MAT-files required: none
%
%   See also: calcErrorEllipseParameters

%   Author: Hanno Winter
%   Date: 13-May-2020; Last revision: 25-March-2021
%

%% Init

if nargin < 5
    resolution = 360;
end % if

if size(pos,1) ~= 2
    error('getXyErrorEllipsePoints: ''pos'' has wrong dimension!');
end % if

rotation_matrix = @(rot_angle_deg) [cosd(rot_angle_deg) -sind(rot_angle_deg);sind(rot_angle_deg) cosd(rot_angle_deg)];

theta_in_deg = linspace(0,5,ceil(0.10*resolution));
theta_in_deg = [theta_in_deg,linspace(5,85,ceil(0.05*resolution))];
theta_in_deg = [theta_in_deg,linspace(85,95,ceil(0.20*resolution))];
theta_in_deg = [theta_in_deg,linspace(95,175,ceil(0.05*resolution))];
theta_in_deg = [theta_in_deg,linspace(175,185,ceil(0.20*resolution))];
theta_in_deg = [theta_in_deg,linspace(185,265,ceil(0.05*resolution))];
theta_in_deg = [theta_in_deg,linspace(265,275,ceil(0.20*resolution))];
theta_in_deg = [theta_in_deg,linspace(275,355,ceil(0.05*resolution))];
theta_in_deg = [theta_in_deg,linspace(355,360,ceil(0.10*resolution))];

%% Calculations

error_ellipse_sep = nan(2,length(theta_in_deg),size(pos,2));
error_ellipse_cmb = nan(2,length(theta_in_deg)+1,size(pos,2));

for i = 1:size(pos,2)
    
    a =  major(i);
    b =  minor(i);
    theta_0 = alpha(i);
    pos_i = pos(:,i);
       
    rho_err_ellipse = zeros(1,length(theta_in_deg));
    for theta_index = 1:length(theta_in_deg)
        gamma_i = theta_in_deg(theta_index);

        if a == 0 && mod(gamma_i+90,180)==0
            rho_err_ellipse(theta_index) = abs(b/sind(gamma_i));
        elseif b == 0 && mod(gamma_i,180)==0
            rho_err_ellipse(theta_index) = abs(a/cosd(gamma_i));
        else
            rho_err_ellipse(theta_index) = a*b/sqrt(a^2*sind(gamma_i)^2+b^2*cosd(gamma_i)^2);
        end % if   
    end % for phi_index
 
    [x_err_ellipse,y_err_ellipse] = pol2cart(theta_in_deg./360*2*pi,rho_err_ellipse);
    err_ellipse = rotation_matrix(theta_0)*[x_err_ellipse;y_err_ellipse];
    
    error_ellipse_sep(1:2,:,i) = [ ... 
                                   err_ellipse(1,:) + pos_i(1); ... 
                                   err_ellipse(2,:) + pos_i(2)  ... 
                                 ];
	error_ellipse_cmb(1:2,1:end-1,i) = error_ellipse_sep(1:2,:,i);
    
end % for i

error_ellipse_cmb = reshape(error_ellipse_cmb,2,size(error_ellipse_cmb,2)*size(error_ellipse_cmb,3));


end

