clearvars;
close all;
clc;

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

outputDirectory = fullfile(projectRoot, 'results');
results = earth_mars_transfer_analysis(outputDirectory, true);

fprintf('\nEarth--Mars transfer study complete\n');
fprintf('Transfer time:          %.2f days\n', results.transferTimeDays);
fprintf('Required phase angle:   %.2f degrees\n', results.phaseAngleDegrees);
fprintf('Earth departure delta-v %.3f km/s\n', results.departureDeltaV_km_s);
fprintf('Mars capture delta-v:   %.3f km/s\n', results.captureDeltaV_km_s);
fprintf('Total impulsive delta-v %.3f km/s\n', results.totalDeltaV_km_s);
fprintf('Numerical arrival miss: %.3f km\n\n', results.arrivalMissDistance_km);

