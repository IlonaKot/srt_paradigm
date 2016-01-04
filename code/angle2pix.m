function pix = angle2pix(ang, dist_cm, screen_w_cm, resolution_x)
% pix = angle2pix(ang, dist_cm, screen_w_cm, resolution_x)
%
% converts visual angles in degrees to pixels.
%
% Inputs:
%       ang             visual angle [deg]
%       dist_cm         distance from the screen [cm]
%       screen_w_cm     width of the screen [cm]
%       resolution_x    horizontal resolution [pixel]
%
% Returns:
%       pix             visual angle in pixels
%
% Warning: assumes isotropic (square) pixels and ignores convexity of the
%          monitor

%Written 11/1/07 gmb zre
% 1/30/15 cleaned code MVdOC
% Credits to Alireza Soltani's codebase

% compute conversion factor cm to pixels
cm2pix = resolution_x/screen_w_cm;  %[pix/cm]

sz = dist_cm*tand(ang);  %[cm]

pix = round(sz*cm2pix);  %[pix]
