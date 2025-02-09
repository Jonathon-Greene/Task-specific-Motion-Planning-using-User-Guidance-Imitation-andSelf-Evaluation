% Script File


%% Section 0 : Initialization

clear all;
close all;
clf;
clc;

%% Section 2 : Load Data %%NC01


% theta : The set of joint angles for the manipulator for the recorded
% motion in the form [S0;S1;E0;E1;W0;W1;W2]

%%%% Memorized Trajectory is R8
% load('R8.mat', 'Endeffector_pose','DualQuaternion','theta','g_st'); % Recorded trajectory
% temp = load ('R9.mat','DualQuaternion'); % Load the new object configuration
%%%% Memorized Trajectory is R4
% %  load('R4.mat','theta','DualQuaternion','g_st'); % Recorded trajectory
%load('R4.mat','theta');
load('water_trans.mat','watertheta');
%fluid_trans1 = fliplr(fluid_trans1);
%newobj =load('R11.mat','g_st');
%temp21 = newobj.g_st(:,:,100);

%% If no denoising then uncomment
%   g_st1 = g_st;
%  theta1 =theta;
%  DualQuaternion1 = DualQuaternion;
%% Denoising using dual quaternion

%[g_st1, theta1,DualQuaternion1] = Denoise( DualQuaternion,theta,g_st);
%% Denoising in joint space
[theta1, g_st1, DualQuaternion1] = denoising(watertheta);

%% Grid
% grid_theta = 1;
% grid_y = 1;
% grid_x = 1;
%Table01(6,6,11) = 0;
%Table01 = zeros(mm,nn,uu);
% Table01 = zeros(11,11,9);
%% New Object configuration
%Original demonstrated motion
% temp21 = [  -0.9751   -0.2151    0.0516    0.8120;
%             -0.2108    0.9743    0.0787     0.1052;
%             -0.0673    0.0659   -0.9954     -0.0245;
%                 0         0         0      1.0000];


% z = -0.0245
% for y = -0.20: 0.12:0.40
 %    for x = 0.6000:0.10:1.1120
  %       for theta2 = 0:0.523:4.712
% for y = 0.05:0.01:0.15
% %for y = 0.05:0.01:0.07
%      for x = 0.72:0.01:0.820
%          %for theta2 = 0:0.1:0.8
%          for theta2 = -0.8:0.1:0
%             [grid_x, grid_y]
%          %   theta2 = 0;
%             R = [cos(theta2) -sin(theta2) 0;
%                 sin(theta2) cos(theta2) 0;
%                 0 0 1;];
%             R_1 =[ -0.9751   -0.2151    0.0516 ;
%                 -0.2108    0.9743    0.0787;
%                 -0.0673    0.0659   -0.9954 ];
%             R_final = R_1*R  ;
            
  %          temp21 =      [ R_final [x;        y;        z]
  %              0         0         0      1.0000];
%  (use this)           temp21 = [  -0.9751   -0.2151    0.0516    0.8120;
%             -0.2108    0.9743    0.0787     0.1052;
%             -0.0673    0.0659   -0.9954     0.45;
%                 0         0         0      1.0000];
% (svmtraj3)  temp21 = [ -0.9864    0.1545    0.0538    0.8149;
%                         0.1526    0.9875   -0.0377    0.1752;
%                        -0.0589   -0.0290   -0.9977   -0.0396;
%                             0         0         0    1.0000];


         temp21 = [      -0.2544   -0.0259    0.9666    0.7276;
   -0.0601    0.9980    0.0108    0.4886;
   -0.9650   -0.0554   -0.2554    0.1796;
         0         0         0     1.0000];

            q = MatrixToDQuaternion(temp21);
            
            %% Section 3: Computes the imitated motion from a new object configuration (q) %NC01
            [ new_pose, g_new] = Transformation1(q,DualQuaternion1'); %NC01
            %% Section 4: Dual Quaternion interpolation %%NC01
            %Parameters:
            % Variable i indexes into the imitated trajectory.
            i = 1; % Pose to start interpolation on imitated motion
            step = 1;
            sam =  25;   % Sample number of the dual quaternion to be taken from the interpolation result
            t = 0.01;   % Interpolation step
            m = 1;      % Error in orientation between current pose and guiding pose on imitated trajectory
            e = 1;      % Error in position between current pose and guiding pose on imitated trajectory
            mf = 1;     % Error in orientation between current pose and final pose.
            ef = 1;     % Error in position between current pose and final pose.
            
            joint_angles(:,1) = theta1(:,1);
            %q1 = DualQuaternion1 (:,1);
            initial_pose = forward_kinematics(theta1(:,1));
            orient_init = initial_pose(1:3,1:3);
            % theta_initial = [ 0.085519; -0.86478;-0.004602; 1.12402; -0.120034; 1.06151;0.368155];
            % joint_angles(:,1) = theta_initial;
            % initial_pose = forward_kinematics(theta_initial);
            
            position_tol = 1e-03;   %%%% NC
            orientation_tol = 1e-03; %%%%   NC
            length_trajectory = size(new_pose,1); %%%% NC
            
            q1 = MatrixToDQuaternion(initial_pose);
            q2 = new_pose(i,:);
            %q2 = new_pose(end,:); % This should give us a velocity IK-based solution without using the demonstrated motion
            [m, e] = convergence_test(q1,q2); %%% New Addition
            if(e > position_tol || m > orientation_tol) % Starting point is not the initial point of imitating trajectory
                [G,result] = ScLERP( q1,q2,t);  % ScLERP is the function for Screw Linear Interpolation %NC01
            end
            S(:,1) = [initial_pose(1:3,4,1)' q1(1,1:4)];
            k = 2;
            
            
            while ef(k-1) > position_tol || mf(k-1) > orientation_tol
                % Compute the desired configuration at any iteration
                if (e(k-1) > position_tol || m(k-1) > orientation_tol)
                    g1(:,:,k) = G(:,:,sam);  % Desired configuration is a point from the interpolation if imitated path is not reached.
                else
                    if (i < length_trajectory)
                        g1(:,:,k) = g_new(:,:,i);  % Desired configuration is on the path if imitated path is reached and all points on
                        i = i+step;% imitated path is not exhausted. Interpolation is not required.
                    else
                        g1(:,:,k) = g_new(:,:,end); % Desired configuration is always the end point once all the points on the imitated path are exhausted.
                    end
                end
                %k
                % Find the new current joint angles and the actual current
                % configuration based on previous actual configuration and current
                % desired configuration
                [J_st,S(:,k),joint_angles(:,k),g_final(:,:,k),q1(k,:)] = redundancy_res_with_JLA(g1(:,:,k),S(:,k-1),joint_angles(:,k-1)); %NC01
                % Compute the distance of current configuration to the next guide
                % configuration on imitated path
                [m(k),e(k)] = convergence_test(q1(k,:),q2);
                % Compute the distance of current configuration to goal configuration
                [mf(k),ef(k)] = convergence_test(q1(k,:),new_pose(end,:));
                
                % Compute interpolated path between current configuration and imitated
                % path when the current configuration is not on imitated path.
                if (e(k) > position_tol || m(k) > orientation_tol) % Assignment of q2 for the next interpolation.
                    if (i < length_trajectory)
                        q2 = new_pose(i,:);  % Guide for interpolation from imitated path if imitated path is not reached and all points on imitated path are not exhausted.
                        %plot3(g_new(1,4,i),g_new(2,4,i),g_new(3,4,i),'Xk');
                        i = i + step;
                    else
                        q2 = new_pose(end,:); % The goal configuration is the guide once all the points on the path are exhausted.
                        sam= 20;
                        %plot3(g_new(1,4,end),g_new(2,4,end),g_new(3,4,end),'Xk');
                    end
                    [G,result] = ScLERP( q1(k,:),q2,t);% Computing Interpolated path from current configuration to a configuration on the imitated path. Interpolation
                    % is done only when the imitated path is not reached.
                end
                if k >2000
                    disp('Not Converging')
        %            Table01(grid_x,grid_y,grid_theta) = true;
                    break;
                end
                k = k+1;
            end
            
            [m(k),e(k)] = convergence_test(q1(k-1,:),new_pose(end,:)); %NC01
            
            %% Check if solution is feasible
            if min(joint_angles(1,:))<-2.461
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 1 violated');
            else if max(joint_angles(1,:))> 0.89
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 1 violated');
                end
            end
            if min(joint_angles(2,:))<-2.147
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 2 violated');
            else if max(joint_angles(2,:))> 1.047
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 2 violated');
                end
            end
            if min(joint_angles(3,:))<-3.028
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 3 violated');
            else if max(joint_angles(3,:))> 3.028
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 3 violated');
                end
            end
            if min(joint_angles(4,:))<-0.052
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 4 violated');
            else if max(joint_angles(4,:))> 2.6180
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 4 violated');
                end
            end
            if min(joint_angles(5,:))<-3.059
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 5 violated');
            else if max(joint_angles(5,:))> 3.059;
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 5 violated');
                end
            end
            if min(joint_angles(6,:))<-1.571
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 6 violated');
            else if max(joint_angles(6,:))> 2.094
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 6 violated');
                end
            end
            if min(joint_angles(7,:))<-3.059
%                 Table01(grid_x,grid_y,grid_theta) = true;
                disp('Lower limit of joint 7 violated');
            else if max(joint_angles(7,:)) > 3.059
%                     Table01(grid_x,grid_y,grid_theta) = true;
                    disp('Upper limit of joint 6 violated');
                end
            end
            
            %%
%             grid_theta= grid_theta+1 %increment angle count
%             clear m e mf ef S joint_angles g_final q1;
%         end
%         grid_theta = 1;
%         grid_x = grid_x+1;
%         %plot_all_fig(g_new, joint_angles,g_final,g_st1,q1(end,:),mf,ef);%NC01
%     end
%     grid_theta = 1;
%     grid_x = 1;
%     grid_y = grid_y+1;
% end
