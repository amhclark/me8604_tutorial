%% Fatigue & Fracture Mechanics
%   Term Project
%   Aidan Clark & Patrick Cleary
clear
close all
clc
format shortEng


%% Input
% Prompt user for input
disp('Enter the following parameters:')
% Geometry
radius = input('Shaft Radius (m): ');
length = input('Shaft Length (m): ');
a = input('Snap Ring Depth (m)');

% Material Properties
yield_strength_MPa = input('Material Yield Strength (MPa): ');
k_Ic_MPa    = input('Critical Fracture Toughness Mode I (MPa.m^(1/2)): ');
% k_IIc_MPa   = input('Critical Fracture Toughness Mode II (MPa.m^(1/2)): ');
k_IIIc_MPa  = input('Critical Fracture Toughness Mode III (MPa.m^(1/2)): ');

% Design Constraints
safety_factor_yielding      = input('Safety Factor against Yielding: ');
safety_factor_fracture_I    = input('Safety Factor against Fracture Mode I: ');
% safety_factor_fracture_II   = input('Safety Factor against Fracture Mode II: ');
safety_factor_fracture_III  = input('Safety Factor against Fracture Mode III: ');

% Loading Conditions
torque = input('Applied Torque (N.m): ');
axial_force = input('Axial Force (N): ');
bending_moment = input('Bending Moment (N.m): ');

% Comparison Option
stress_analysis_type = input('Select Comparison Option (1 for Maximum Shear, 2 for Octahedral): ');

% Input Data Unit Conversion
yield_strength = 10e-6 * yield_strength_MPa; %Pa
k_Ic = k_Ic_MPa * 10e-6;
% k_IIc = k_IIc_MPa * 10e-6;
k_IIIc = k_IIIc_MPa * 10e-6;

%% Part I Calculations

% Geometric Calculations
area = pi * radius^2;

polar_moment_of_inertia = (pi*radius^4)/2;
moment_of_inertia = (pi*radius^4)/4;

% Torsional stress
torsional_stress = torque * radius / polar_moment_of_inertia;

% Axial stress
normal_stress_axial = axial_force / area;

% Bending stress
bending_stress = bending_moment * radius / moment_of_inertia;

% Principal Stress
sigma_x = bending_stress + normal_stress_axial;
sigma_y = 0;
sigma_z = 0;
tau_xy = torsional_stress;
tau_yz = 0;
tau_zx = 0;

% 3D stress state solution
I1 = sigma_x + sigma_y + sigma_z;
I2 = sigma_x*sigma_y + sigma_y*sigma_z + sigma_z*sigma_x + tau_xy^2 + tau_yz^2 + tau_zx^2;
I3 = sigma_x*sigma_y*sigma_z + 2*tau_xy*tau_yz*tau_zx - sigma_x*tau_yz^2 - sigma_y*tau_zx^2 - sigma_z*tau_xy^2;

principal_stresses = sort(roots([1 -1*I1 +I2 -I3]));    % Sorted roots of cubic 3d stress equation
sigma_1 = principal_stresses(3);                        % Principal stress definition based on common practice nomenclature
sigma_2 = principal_stresses(1);
sigma_3 = principal_stresses(2);

% Effective stress based on user's choice
if stress_analysis_type == 1
    % Maximum shear stress
    effective_stress = max([abs(sigma_1 - sigma_2) abs(sigma_2 - sigma_3) abs(sigma_3 - sigma_1)]);
elseif stress_analysis_type == 2
    % Octahedral stress
    effective_stress = (1/sqrt(2))*sqrt((sigma_1 - sigma_2)^2 + (sigma_2 - sigma_3)^2 + (sigma_3 - sigma_1)^2);
else
    error('Invalid stress analysis type option');
end

% Safety Factor
safety_factor = safety_factor_yielding/effective_stress;

%% Part II Calculations

Alpha = a/radius;
Beta = 1 - Alpha;

% LEFM Check
LHS = 2.5*(k/yield_strength_MPa);


% Fracture Mechanics
s_g_axial = axial_force/(pi*radius^2);
F_axial = (1/2*Beta^1.5)*(1 + 0.5*Beta + (3/8)*Beta^2 - 0.363*Beta^3 + 0.731*Beta^4);
k_axial = s_g_axial*F_axial*sqrt(pi*a);

s_g_bending = (4*bending_moment)/(pi*radius^3);
F_bending = (3/(8*Beta^2.5))*(1 +0.5*Beta + (3/8)*Beta^2 + (5/16)*Beta^3 + (35/128)*Beta^4 + 0.537*Beta^5);
k_bending = s_g_bending*F_bending*sqrt(pi*a);

s_g_torsion = (2*torque)/(pi*radius^3);
F_torsion = (3/(8*Beta^2.5))*(1 + 0.5*Beta + (3/8)*Beta^2 + (5/16)*Beta^3 + (35/128)*Beta^4 + 0.537*Beta^5);
k_torsion = s_g_torsion*F_torsion*sqrt(pi*a);

k_I = k_axial + k_bending;
k_III = k_torsion;

% Safety Factors against fracture
safety_factor_fracture_I = k_Ic / k_I;
safety_factor_fracture_III = k_IIIc / k_III;

% Safety Factors against fully plastic yielding

torsion_yield = yield_strength/sqrt(3); %Torsional Yield wrt Octahedral Stress relationship

plastic_force = yield_strength*pi*r^2*(1-Alpha)^2;
plastic_moment = (4/3)*radius^3*yield_strength*(1-Alpha)^3; 
plastic_torque = (2/3)*pi*radius^3*(1-Alpha)^3*torsion_yield;

plastic_force_fos = plastic_force/axial_force;
plastic_moment_fos = plastic_moment/bending_moment;
plastic_torque_fos = plastic_torque/torque;


%% Result Output

% Display results
disp('----- Results (Part I) -----');
disp('Principal Stresses (Pa):');
disp(principal_stresses);
disp(['Effective Stress (Pa): ', num2str(effective_stress)]);
disp(['Safety Factor: ', num2str(safety_factor)]);
disp(' ')
disp(' ')
disp('----- Results (Part II) -----')
disp(['Safety Factor against Yielding: ', num2str(safety_factor_yielding_actual)]);
disp(['Safety Factor against Fracture Mode I: ', num2str(safety_factor_fracture_I)]);
disp(['Safety Factor against Fracture Mode III: ', num2str(safety_factor_fracture_III)]);
disp(['Axial Load Factor of Safety against Plastic Yielding: ', num2string(plastic_force_fos)]);
disp(['Bending Moment Load Factor of Safety against Plastic Yielding: ', num2string(plastic_moment_fos)]);
disp(['Torque Load Factor of Safety against Plastic Yielding: ', num2string(plastic_torque_fos)]);
Part I: Results .txt File

% Part I: Results .txt File
output_file_part_I = fopen('output_report_part_I.txt', 'w');

fprintf(output_file_part_I,'----- User Input -----\n');
fprintf(output_file_part_I, 'Radius (m) %f\n', radius);
fprintf(output_file_part_I, 'Length (m) %f\n', length);
fprintf(output_file_part_I, 'Yield Strength (MPa) %f\n', yield_strength_MPa);
fprintf(output_file_part_I, 'Torque (Nm) %f\n', torque);
fprintf(output_file_part_I, 'Axial Force (N) %f\n', axial_force);
fprintf(output_file_part_I, 'Bending Moment (N/m) %f\n', bending_moment);
fprintf(output_file_part_I, '----- Results -----\n');
fprintf(output_file_part_I, 'Principal Stresses (Pa):\n');
fprintf(output_file_part_I, '%f\n', principal_stresses);
fprintf(output_file_part_I, 'Effective Stress (Pa): %f\n', effective_stress);
fprintf(output_file_part_I, 'Safety Factor: %f\n', safety_factor);

fclose(output_file_part_I);
disp('Report of Analysis Part I saved as output_report_part_I.txt')


% Part II: Results .txt File
output_file_part_II = fopen('output_report_part_II.txt', 'w');
fprintf(output_file_part_II,'----- User Input -----\n');
fprintf(output_file_part_II, 'Snap Ring Depth (m) %f\n', a);
fprintf(output_file_part_II, 'Fracture Toughness I %f\n', k_Ic_MPa);
fprintf(output_file_part_II, 'Fracture Toughness III %f\n', k_IIIc_MPa);
fprintf(output_file_part_II, 'Safety Factor Yielding %f\n', safety_factor_yielding);
fprintf(output_file_part_II, 'Safety Factor Fracture I %f\n', safety_factor_fracture_I);
fprintf(output_file_part_II, 'Safety Factor Fracture III %f\n', safety_factor_fracture_III);
fprintf(output_file_part_II, '----- Results -----\n');
fprintf(output_file_part_II, 'Fracture Toughness (Axial): %f\n', k_axial);
fprintf(output_file_part_II, 'Fracture Toughness (Bending): %f\n', k_bending);
fprintf(output_file_part_II, 'Fracture Toughness (Torsion): %f\n', k_torsion);
fprintf(output_file_part_II, 'Fracture Toughness (Mode I): %f\n', k_I);
fprintf(output_file_part_II, 'Fracture Toughness (Mode III): %f\n', k_III);
fprintf(output_file_part_II, 'Torsion Yield Strength: %f\n', torsion_yield);
fprintf(output_file_part_II, 'Plastic Stress (Axial): %f\n', plastic_force);
fprintf(output_file_part_II, 'Plastic Stress (Bending): %f\n', plastic_moment);
fprintf(output_file_part_II, 'Plastic Stress (Torsion): %f\n', plastic_torque);
fprintf(output_file_part_II, 'Plastic Yield FOS (Axial): %f\n', plastic_force_fos);
fprintf(output_file_part_II, 'Plastic Yield FOS (Bending): %f\n', plastic_moment_fos);
fprintf(output_file_part_II, 'Plastic Yield FOS (Torsion): %f\n', plastic_torque_fos);