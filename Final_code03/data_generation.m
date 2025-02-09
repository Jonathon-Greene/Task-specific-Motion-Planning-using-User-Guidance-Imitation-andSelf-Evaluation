%% Data Generation 1
% Script for generating discrete data in the x-y plane 
clear
clc
close all;


load('C:\Users\QKX486\Documents\MATLAB\SBU\MEC696_II\Examples_b\traj_data_1b.mat');
theta1 = theta';
[theta1, g_st1, DualQuaternion1] = denoising(theta1);  

%Resolution options
% 0.015 = _highres
% 0.05 = _temp

delta_x = .05; % Meters. X distance between each discrete point. 
x_range = 0.6; % Meters. X overall dimension of the desired workspace, 
%centered about x_demo

delta_y = .05; % Meters. Y distance between each discrete point
y_range = 1.2; % Meters. Y overall dimension of the desired workspace, 
%centered about y_demo

delta_z_angle = pi/6; % Radians. Assuming that we will be only rotating
%about z-axis of demo configuration. Rotation incriment about each discrete
%rotation.
rot_range = pi/2; % Radians. Total rotation range to test across. 

z_offset = 0.110; % Meters. Distance to raise workplane above last
%demonstration point


T_demo = g_st1(:,:,end); % Final ee configuration for demo
R_demo = T_demo(1:3,1:3);%Rotation matrix of the Final Configuration
x_demo = T_demo(1,4); y_demo = T_demo(2,4); z_demo = T_demo(3,4)+z_offset;

% Range of x-coordinates
x_min = x_demo - x_range/2;
x_max = x_demo + x_range/2;

% Range of y-coordinates
y_min = y_demo - y_range/2;
y_max = y_demo + y_range/2;

% Range of angular deviation about z-axis of final orientation in demo
del_rot_min = 0 - rot_range;
del_rot_max = 0 + rot_range;

count=1;
for x = x_min:delta_x:x_max
    for y = y_min:delta_y:y_max
        for del_rot=del_rot_min:delta_z_angle:del_rot_max
            P = [x y z_demo]';
            
            delRz = [cos(del_rot) -sin(del_rot) 0; ...
                sin(del_rot) cos(del_rot) 0; ...
                0 0 1]; % deviation of current orientation from demo
                % orientation (z axis)

            delRy = [cos(del_rot) 0 sin(del_rot); ...
                0 1 0; ...
                -sin(del_rot) 0 cos(del_rot)]; % deviation of current ...
                % orientation from demo orientation (y axis)

             delR = delRz*delRy;   
            
            %delR = [cos(del_rot) -sin(del_rot) 0; ...
                %sin(del_rot) cos(del_rot) 0; ...
                %0 0 1]; % deviation of current orientation from demo orientation
            Temp(:,:,count) = [R_demo*delR P ; zeros(1,3) 1] ;
            count = count+1;
        end
    end
end
count_scenario = size(Temp,3);

save('C:\Users\QKX486\Documents\MATLAB\SBU\MEC696_II\Results_b\traj_data_1b_z11_temp.mat','Temp','count_scenario')