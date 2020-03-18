function [x, y, z] = antenna_to_cartesian(ranges, azimuths, elevations, h)
% copy from https://github.com/YvZheng/pycwr/blob/master/pycwr/core/transforms.py#L106-L154
% Return Cartesian coordinates from antenna coordinates.
% Parameters
% ----------
% ranges : array
%     Distances to the center of the radar gates (bins) in meters.
% azimuths : array
%     Azimuth angle of the radar in degrees.
% elevations : array
%     Elevation angle of the radar in degrees.
% h : constant
%     Altitude of the instrument, above sea level, units:m.
% Returns
% -------
% x, y, z : array
%     Cartesian coordinates in meters from the radar.
% Notes
% -----
% The calculation for Cartesian coordinate is adapted from equations
% 2.28(b) and 2.28(c) of Doviak and Zrnic [1]_ assuming a
% standard atmosphere (4/3 Earth's radius model).
% .. math::
%     z = \\sqrt{r^2+R^2+2*r*R*sin(\\theta_e)} - R
%     s = R * arcsin(\\frac{r*cos(\\theta_e)}{R+z})
%     x = s * sin(\\theta_a)
%     y = s * cos(\\theta_a)
% Where r is the distance from the radar to the center of the gate,
% :math:`\\theta_a` is the azimuth angle, :math:`\\theta_e` is the
% elevation angle, s is the arc length, and R is the effective radius
% of the earth, taken to be 4/3 the mean radius of earth (6371 km).
% References
% ----------
% .. [1] Doviak and Zrnic, Doppler Radar and Weather Observations, Second
%     Edition, 1993, p. 21.
   
theta_e = deg2rad(elevations);  % elevation angle in radians.
theta_a = deg2rad(azimuths);  % azimuth angle in radians.
R = 6371.0 * 1000.0 * 4.0 / 3.0;  % effective radius of earth in meters.
r = ranges * 1.0;  % distances to gates in meters.

z = ((r .* cos(theta_e)).^2 + (R + h + r .* sin(theta_e)).^2).^0.5 - R;
s = R * asin(r .* cos(theta_e) ./ (R + z));  % arc length in km.
x = s .* sin(theta_a);
y = s .* cos(theta_a);

end