% Distance geometry software GPS receiver
%------------------------------------------------------------------------ 
% 
% This program provides GPS receiver functionality for post-processing
% data recorded in Receiver Independant Exchange (RINEX) files. The
% positioning algorithm is based on a distance geoemetry approach
% introduced by Shahrdad Tabib* and is part of an ongoing research project
% at the University of California, Davis.
%
% Input:
% Navigation RINEX file
% Observation RINEX file
%
% Output:
% GPS position estimates in an ECEF reference frame (X, Y, Z)
% GPS position estimates in a geographic reference frame (lat., long., h)
%
%------------------------------------------------------------------------
%
% * Tabib, S., A coordinate free distance geometry approach to the GPS and 
% kinematical computations for general localization, Ph.D. thesis,
% University of California, Davis (2007).
%
%------------------------------------------------------------------------
%
% Copyright 2016, Hadi Tabatabaee, All rights reserved.
%
%------------------------------------------------------------------------

% Loading RINEX navigation file
% [Eph, iono, constellations] = load_RINEX_nav('brdm1660.13p', [], 0);
[Eph, iono, constellations] = load_RINEX_nav('site247j.01n', [], 0);

% Loading RINEX observation file
% [pr1, ph1, pr2, ph2, dop1, dop2, snr1, snr2, time_ref, time, week, date, pos, interval, antoff, antmod, codeC1] = load_RINEX_obs('gmsd1660_cut.13o', []);
[pr1, ph1, pr2, ph2, dop1, dop2, snr1, snr2, time_ref, time, week, date, pos, interval, antoff, antmod, codeC1] = load_RINEX_obs('site247j.01o', []);

nEpochs = length(time);      


nSatTot = constellations.nEnabledSat;
err_iono = zeros(nSatTot,nEpochs);
err_tropo = zeros(nSatTot,nEpochs);            
dtR1 = zeros(length(time),1);
dtR2 = zeros(length(time),1);
dtR3 = zeros(length(time),1);
dtR_dot = zeros(length(time),1);
XR1 = zeros(3, length(time));
XS = zeros(4, 3, length(time));
time_interval = interval; %initialization of time interval
c = 299792458;

% Locate satellites using Eph (this will need receiver clock bias as input)
% For now assume dtR = 0 for first epoch.


for i = 1 : length(time)
    sat0 = find(pr1(:,i) ~= 0);

    [XS, dtS, XS_tx, VS_tx, time_tx, no_eph, sys, traveltime] = satellite_positions(time(i), pr1(:,i), sat0, Eph, [], [], err_tropo, err_iono, dtR1(i,1));
    XS = XS';
    pr = pr1(sat0, i);
    pr = pr + c*dtS;
%     pr = pr(1:4);
%     XS = XS(:, 1:4);
%     


    [XR1(:,i), dtR1(i)] = distG(XS, pr);
     
    [XR3(:,i), ~,dtR3(i)] = leastSquare_eff(XS, pr);
 

    [PDOP(i), HDOP(i), VDOP(i), ~, ~] = DOP(pos, XS);
    
    pr = pr(1:4);
    XS = XS(:, 1:4);
    
    [XR2(:,i), dtR2(i)] = DG4sat(XS, pr);
    
end      



% Saving outputs
% time_stamp = datestr(now, 'mmddyyHHMMSS');
% mkdir(strcat('./data/', 'DG_', time_stamp));
% pathname = strcat('./data/', 'DG_', time_stamp, '/');
% save(strcat(pathname,'DG_XR_', time_stamp), 'XR');
% save(strcat(pathname,'DG_time_', time_stamp), 'time');
% save(strcat(pathname,'DG_dtR_', time_stamp), 'dtR');
% save(strcat(pathname,'DG_pr1_', time_stamp), 'pr1');

legend1 = 'DG - modified';
legend2 = 'DG - 4 sats';
legend3 = 'Least Squares';
legend4 = 'Real Position';

figure
subplot(3,1,1); title('X - coordinate (ECEF)');
ylabel('X (m)')
hold on
plot(1:nEpochs, XR1(1,:) - pos(1))
plot(1:nEpochs, XR2(1,:) - pos(1))
plot(1:nEpochs, XR3(1,:) - pos(1))
plot(1:nEpochs, 0*pos(1)*ones(nEpochs,1))
legend(legend1, legend2, legend3, legend4)

subplot(3,1,2); title('Y - coordinate (ECEF)');
ylabel('Y (m)')
hold on
%plot(1:400, XR(1,:))
plot(1:nEpochs, XR1(2,:) - pos(2))
plot(1:nEpochs, XR2(2,:) - pos(2))
plot(1:nEpochs, XR3(2,:) - pos(2))
plot(1:nEpochs, 0*pos(2)*ones(nEpochs,1))
legend(legend1, legend2, legend3, legend4)

subplot(3,1,3); title('Z - coordinate (ECEF)');
ylabel('Z (m)')
xlabel('Time (s)')
hold on
%plot(1:400, XR(1,:))
plot(1:nEpochs, XR1(3,:) - pos(3))
plot(1:nEpochs, XR2(3,:) - pos(3))
plot(1:nEpochs, XR3(3,:) - pos(3))
plot(1:nEpochs, 0*pos(3)*ones(nEpochs,1))
legend(legend1, legend2, legend3, legend4)



%% Convert from ECEF to geographic coordinates
clear h


[phi(:), lam(:), h(:)] = cart2geod(XR1(1,:), XR1(2,:), XR1(3,:));
[phi2(:), lam2(:), h2(:)] = cart2geod(XR2(1,:), XR2(2,:), XR2(3,:));
[phi_LS(:), lam_LS(:), h_LS(:)] = cart2geod(XR3(1,:), XR3(2,:), XR3(3,:));
[phi_pos, lam_pos, h_pos] = cart2geod(pos(1), pos(2), pos(3));

% Convert to degrees
phi_pos = (phi_pos./pi)*180;
lam_pos = (lam_pos./pi)*180;

% Convert and normalize
phi = (phi./pi)*180 - phi_pos;
lam = (lam./pi)*180 - lam_pos;
phi2 = (phi2./pi)*180 - phi_pos;
lam2 = (lam2./pi)*180 - lam_pos;
phi_LS = (phi_LS./pi)*180 - phi_pos;
lam_LS = (lam_LS./pi)*180 - lam_pos;



figure
title('Geographic coordinates')
subplot(3,1,1); title('Longitude');
xlim([0 nEpochs]);
hold on
plot(phi)
plot(phi2)
plot(phi_LS)
plot(1:nEpochs, 0*phi_pos*ones(nEpochs,1))
legend(legend1, legend2, legend3, legend4)
hold off

subplot(3,1,2); title('Latitude');
xlim([0 nEpochs]);
hold on
plot(lam)
plot(lam2)
plot(lam_LS)
plot(1:nEpochs, 0*lam_pos*ones(nEpochs,1))
legend(legend1, legend2, legend3, legend4)
hold off

subplot(3,1,3); title('Elevation (m)');
xlim([0 nEpochs]);
hold on
plot(h-h_pos*ones(1,nEpochs))
plot(h2-h_pos*ones(1,nEpochs))
plot(h_LS-h_pos*ones(1,nEpochs))
plot(1:nEpochs, 0*h_pos*ones(nEpochs,1))
legend(legend1, legend2, legend3, legend4)
hold off

%%
for i = 1:nEpochs
    norm1(i) = norm(XR1(:,i) - pos);
    norm2(i) = norm(XR2(:,i) - pos);
    norm3(i) = norm(XR3(:,i) - pos);
end

figure
subplot(2,1,1); title('3D positioning error (m)');
ylabel('Error (m)')
xlabel('Time (s)')
hold on

plot(1:nEpochs, norm1)
plot(1:nEpochs, norm2)
plot(1:nEpochs, norm3)

legend(legend1, legend2, legend3)

subplot(2,1,2); title('Dilution of Precision');
ylabel('DOP')
xlabel('Time (s)')
hold on
plot(1:nEpochs, PDOP(:));



