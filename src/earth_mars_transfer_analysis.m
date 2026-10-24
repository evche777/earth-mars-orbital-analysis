function results = earth_mars_transfer_analysis(outputDirectory, makePlots)
%EARTH_MARS_TRANSFER_ANALYSIS Introductory Earth-to-Mars trajectory study.
%
% The model combines:
%   1. Circular, coplanar heliocentric orbits for Earth and Mars.
%   2. A minimum-energy Hohmann transfer between those orbits.
%   3. Patched-conic estimates for departure from a 300 km LEO and
%      capture into a 300 km circular Mars orbit.
%   4. Numerical two-body propagation with ODE45 as an independent check
%      of the analytic transfer geometry.
%
% This is an educational analysis, not a flight-ready mission design.

if nargin < 1 || isempty(outputDirectory)
    outputDirectory = fullfile(pwd, 'results');
end
if nargin < 2
    makePlots = true;
end

if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
figureDirectory = fullfile(outputDirectory, 'figures');
if makePlots && ~exist(figureDirectory, 'dir')
    mkdir(figureDirectory);
end

%% Reference constants (km, s)
day = 86400;
AU = 149597870.7;

muSun = 1.32712440041279419e11;
muEarth = 398600.435507;
muMars = 42828.375816;

earthRadius = 6378.1363;
marsRadius = 3396.19;

earthOrbitRadius = AU;
marsOrbitRadius = 1.523679 * AU;

earthParkingAltitude = 300;
marsCaptureAltitude = 300;

%% Analytic heliocentric Hohmann transfer
transferSemiMajorAxis = 0.5 * (earthOrbitRadius + marsOrbitRadius);
transferTime = pi * sqrt(transferSemiMajorAxis^3 / muSun);

earthCircularSpeed = sqrt(muSun / earthOrbitRadius);
marsCircularSpeed = sqrt(muSun / marsOrbitRadius);

transferSpeedAtEarth = sqrt(muSun * ...
    (2 / earthOrbitRadius - 1 / transferSemiMajorAxis));
transferSpeedAtMars = sqrt(muSun * ...
    (2 / marsOrbitRadius - 1 / transferSemiMajorAxis));

earthDepartureVInfinity = transferSpeedAtEarth - earthCircularSpeed;
marsArrivalVInfinity = marsCircularSpeed - transferSpeedAtMars;

earthMeanMotion = sqrt(muSun / earthOrbitRadius^3);
marsMeanMotion = sqrt(muSun / marsOrbitRadius^3);

phaseAngle = pi - marsMeanMotion * transferTime;
synodicPeriod = 2 * pi / abs(earthMeanMotion - marsMeanMotion);

%% Patched-conic departure and capture estimates
earthParkingRadius = earthRadius + earthParkingAltitude;
marsCaptureRadius = marsRadius + marsCaptureAltitude;

earthParkingSpeed = sqrt(muEarth / earthParkingRadius);
earthHyperbolicPeriapsisSpeed = sqrt(earthDepartureVInfinity^2 + ...
    2 * muEarth / earthParkingRadius);
departureDeltaV = earthHyperbolicPeriapsisSpeed - earthParkingSpeed;

marsCircularCaptureSpeed = sqrt(muMars / marsCaptureRadius);
marsHyperbolicPeriapsisSpeed = sqrt(marsArrivalVInfinity^2 + ...
    2 * muMars / marsCaptureRadius);
captureDeltaV = marsHyperbolicPeriapsisSpeed - marsCircularCaptureSpeed;

totalDeltaV = departureDeltaV + captureDeltaV;

%% Numerical propagation of the heliocentric transfer
initialState = [earthOrbitRadius; 0; 0; transferSpeedAtEarth];
integrationOptions = odeset( ...
    'RelTol', 1e-11, ...
    'AbsTol', 1e-10, ...
    'MaxStep', transferTime / 600);

[time, state] = ode45( ...
    @(t, x) two_body_rhs(t, x, muSun), ...
    [0, transferTime], ...
    initialState, ...
    integrationOptions);

earthAngle = earthMeanMotion * time;
marsAngle = phaseAngle + marsMeanMotion * time;

earthPosition = earthOrbitRadius * [cos(earthAngle), sin(earthAngle)];
marsPosition = marsOrbitRadius * [cos(marsAngle), sin(marsAngle)];

arrivalMissDistance = norm(state(end, 1:2) - marsPosition(end, :));

radiusMagnitude = sqrt(sum(state(:, 1:2).^2, 2));
speedSquared = sum(state(:, 3:4).^2, 2);
specificEnergy = 0.5 * speedSquared - muSun ./ radiusMagnitude;
specificAngularMomentum = ...
    state(:, 1) .* state(:, 4) - state(:, 2) .* state(:, 3);

relativeEnergyError = abs((specificEnergy - specificEnergy(1)) ...
    / specificEnergy(1));
relativeAngularMomentumError = abs( ...
    (specificAngularMomentum - specificAngularMomentum(1)) ...
    / specificAngularMomentum(1));

%% Sensitivity to departure timing around the ideal Hohmann window
departureOffsetDays = (-120:1:120)';
relativePhaseShift = (marsMeanMotion - earthMeanMotion) ...
    .* departureOffsetDays .* day;

idealSpacecraftArrival = [-marsOrbitRadius, 0];
offsetMarsArrival = marsOrbitRadius * ...
    [cos(pi + relativePhaseShift), sin(pi + relativePhaseShift)];
timingMissDistance = sqrt(sum( ...
    (offsetMarsArrival - idealSpacecraftArrival).^2, 2));

%% Results structure
results.transferSemiMajorAxis_AU = transferSemiMajorAxis / AU;
results.transferTimeDays = transferTime / day;
results.phaseAngleDegrees = rad2deg(phaseAngle);
results.synodicPeriodDays = synodicPeriod / day;
results.earthDepartureVInfinity_km_s = earthDepartureVInfinity;
results.marsArrivalVInfinity_km_s = marsArrivalVInfinity;
results.departureDeltaV_km_s = departureDeltaV;
results.captureDeltaV_km_s = captureDeltaV;
results.totalDeltaV_km_s = totalDeltaV;
results.arrivalMissDistance_km = arrivalMissDistance;
results.maximumRelativeEnergyError = max(relativeEnergyError);
results.maximumRelativeAngularMomentumError = ...
    max(relativeAngularMomentumError);

%% Save numerical summary
write_summary_files(outputDirectory, results);

%% Figures
if makePlots
    create_figures( ...
        figureDirectory, AU, day, time, state, ...
        earthPosition, marsPosition, earthOrbitRadius, marsOrbitRadius, ...
        phaseAngle, departureOffsetDays, timingMissDistance, ...
        relativeEnergyError, relativeAngularMomentumError, ...
        departureDeltaV, captureDeltaV);
end
end

function write_summary_files(outputDirectory, results)
summaryPath = fullfile(outputDirectory, 'summary.txt');
fileId = fopen(summaryPath, 'w');
cleanupObject = onCleanup(@() fclose(fileId)); %#ok<NASGU>

fprintf(fileId, 'EARTH--MARS HOHMANN TRANSFER STUDY\n');
fprintf(fileId, '=================================\n\n');
fprintf(fileId, 'Transfer semi-major axis:    %.6f AU\n', ...
    results.transferSemiMajorAxis_AU);
fprintf(fileId, 'Transfer time:               %.6f days\n', ...
    results.transferTimeDays);
fprintf(fileId, 'Required Mars phase angle:   %.6f deg\n', ...
    results.phaseAngleDegrees);
fprintf(fileId, 'Earth--Mars synodic period:  %.6f days\n', ...
    results.synodicPeriodDays);
fprintf(fileId, 'Earth departure v-infinity:  %.6f km/s\n', ...
    results.earthDepartureVInfinity_km_s);
fprintf(fileId, 'Mars arrival v-infinity:     %.6f km/s\n', ...
    results.marsArrivalVInfinity_km_s);
fprintf(fileId, 'LEO departure delta-v:       %.6f km/s\n', ...
    results.departureDeltaV_km_s);
fprintf(fileId, 'Mars capture delta-v:        %.6f km/s\n', ...
    results.captureDeltaV_km_s);
fprintf(fileId, 'Total impulsive delta-v:     %.6f km/s\n', ...
    results.totalDeltaV_km_s);
fprintf(fileId, 'Numerical arrival miss:      %.6f km\n', ...
    results.arrivalMissDistance_km);
fprintf(fileId, 'Maximum relative energy error:     %.3e\n', ...
    results.maximumRelativeEnergyError);
fprintf(fileId, 'Maximum relative momentum error:   %.3e\n', ...
    results.maximumRelativeAngularMomentumError);

csvPath = fullfile(outputDirectory, 'summary.csv');
fileIdCsv = fopen(csvPath, 'w');
cleanupObjectCsv = onCleanup(@() fclose(fileIdCsv)); %#ok<NASGU>

fprintf(fileIdCsv, 'quantity,value,unit\n');
fprintf(fileIdCsv, 'transfer_semi_major_axis,%.10f,AU\n', ...
    results.transferSemiMajorAxis_AU);
fprintf(fileIdCsv, 'transfer_time,%.10f,days\n', ...
    results.transferTimeDays);
fprintf(fileIdCsv, 'required_phase_angle,%.10f,degrees\n', ...
    results.phaseAngleDegrees);
fprintf(fileIdCsv, 'synodic_period,%.10f,days\n', ...
    results.synodicPeriodDays);
fprintf(fileIdCsv, 'earth_departure_v_infinity,%.10f,km/s\n', ...
    results.earthDepartureVInfinity_km_s);
fprintf(fileIdCsv, 'mars_arrival_v_infinity,%.10f,km/s\n', ...
    results.marsArrivalVInfinity_km_s);
fprintf(fileIdCsv, 'leo_departure_delta_v,%.10f,km/s\n', ...
    results.departureDeltaV_km_s);
fprintf(fileIdCsv, 'mars_capture_delta_v,%.10f,km/s\n', ...
    results.captureDeltaV_km_s);
fprintf(fileIdCsv, 'total_impulsive_delta_v,%.10f,km/s\n', ...
    results.totalDeltaV_km_s);
fprintf(fileIdCsv, 'numerical_arrival_miss,%.10f,km\n', ...
    results.arrivalMissDistance_km);
end

function create_figures( ...
    figureDirectory, AU, day, time, state, earthPosition, marsPosition, ...
    earthOrbitRadius, marsOrbitRadius, phaseAngle, departureOffsetDays, ...
    timingMissDistance, relativeEnergyError, ...
    relativeAngularMomentumError, departureDeltaV, captureDeltaV)

orbitAngle = linspace(0, 2 * pi, 720);

figureHandle = figure('Color', 'w', 'Visible', 'off');
hold on;
plot(cos(orbitAngle), sin(orbitAngle), '--', ...
    'Color', [0.25, 0.45, 0.85], 'LineWidth', 1.0);
plot((marsOrbitRadius / AU) * cos(orbitAngle), ...
    (marsOrbitRadius / AU) * sin(orbitAngle), '--', ...
    'Color', [0.85, 0.35, 0.20], 'LineWidth', 1.0);
plot(state(:, 1) / AU, state(:, 2) / AU, ...
    'k-', 'LineWidth', 2.2);
plot(0, 0, 'o', 'MarkerSize', 12, ...
    'MarkerFaceColor', [1.0, 0.75, 0.05], 'MarkerEdgeColor', 'none');
plot(1, 0, 'o', 'MarkerSize', 8, ...
    'MarkerFaceColor', [0.20, 0.45, 0.95], 'MarkerEdgeColor', 'none');
plot((marsOrbitRadius / AU) * cos(phaseAngle), ...
    (marsOrbitRadius / AU) * sin(phaseAngle), 'o', 'MarkerSize', 8, ...
    'MarkerFaceColor', [0.90, 0.30, 0.15], 'MarkerEdgeColor', 'none');
plot(marsPosition(end, 1) / AU, marsPosition(end, 2) / AU, 's', ...
    'MarkerSize', 8, 'MarkerFaceColor', [0.90, 0.30, 0.15], ...
    'MarkerEdgeColor', 'none');
axis equal;
grid on;
xlabel('Heliocentric x [AU]');
ylabel('Heliocentric y [AU]');
title('Earth--Mars minimum-energy transfer');
legend({'Earth orbit', 'Mars orbit', 'Numerical trajectory', ...
    'Sun', 'Earth at departure', 'Mars at departure', ...
    'Mars at arrival'}, 'Location', 'bestoutside');
print(figureHandle, fullfile(figureDirectory, ...
    'trajectory_overview.png'), '-dpng', '-r200');
close(figureHandle);

figureHandle = figure('Color', 'w', 'Visible', 'off');
plot(departureOffsetDays, timingMissDistance / 1e6, ...
    'LineWidth', 2.0, 'Color', [0.45, 0.20, 0.70]);
hold on;
plot(0, 0, 'o', 'MarkerSize', 7, ...
    'MarkerFaceColor', [0.15, 0.65, 0.35], 'MarkerEdgeColor', 'none');
grid on;
xlabel('Departure timing offset from ideal window [days]');
ylabel('Mars arrival miss distance [million km]');
title('Sensitivity to departure timing');
print(figureHandle, fullfile(figureDirectory, ...
    'launch_window_sensitivity.png'), '-dpng', '-r200');
close(figureHandle);

figureHandle = figure('Color', 'w', 'Visible', 'off');
semilogy(time / day, max(relativeEnergyError, eps), ...
    'LineWidth', 1.8);
hold on;
semilogy(time / day, max(relativeAngularMomentumError, eps), ...
    'LineWidth', 1.8);
grid on;
xlabel('Time since departure [days]');
ylabel('Relative conservation error');
title('Numerical propagation checks');
legend({'Specific orbital energy', 'Specific angular momentum'}, ...
    'Location', 'best');
print(figureHandle, fullfile(figureDirectory, ...
    'numerical_conservation.png'), '-dpng', '-r200');
close(figureHandle);

figureHandle = figure('Color', 'w', 'Visible', 'off');
bar([departureDeltaV, captureDeltaV], 0.55, ...
    'FaceColor', [0.20, 0.55, 0.75]);
set(gca, 'XTick', [1, 2], ...
    'XTickLabel', {'LEO departure', 'Mars capture'});
ylabel('\Delta v [km/s]');
title('Idealised impulsive delta-v budget');
grid on;
print(figureHandle, fullfile(figureDirectory, ...
    'delta_v_budget.png'), '-dpng', '-r200');
close(figureHandle);
end

