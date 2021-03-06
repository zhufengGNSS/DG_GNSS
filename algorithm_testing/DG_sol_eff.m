function [XR, dtR] = DG_sol_eff(XS, r)
% This function provides GPS reciever location using the distance geometry
% method for over-determined problems (n>4).
% ------------------------------------------------------------------------
% Input:
%       XS  =  3xn matrix containing satellite coordinates
%       pr  =  nx1 vector containing observed pseudoranges
% Output:
%       XR  =  3x1 vector of receiver location
%       dtR = receiver clock bias in seconds (scalar)
% ------------------------------------------------------------------------
%   Copyright 2016, Hadi Tabatabaee. All rights reserved.
% ------------------------------------------------------------------------
% Defining needed variables:
n = length(r);
Ar = zeros(n);
hr = ones(n,1);
c = 299792458; % speed of light.
P = eye(n) - 1/n*ones(n,n);

% Creating distance geometry reference matrix
for i = 1:n
    for j = 1:n
        tmp = XS(:,i) - XS(:,j);
        Ar(i,j) = tmp'*tmp;
    end
end
    
% form u & r vectors
u = diag(r*r');
    
% weighting constants
tol = 25;
k_const = 100;

% Ar*x = u solution

Apinv = pinv(P*Ar + k_const*(ones(n,n)), tol);

x_ur = Apinv*(P*u + k_const*hr);
x_ur_last = (1/n)*hr'*(u - Ar*x_ur);

x_u = [x_ur; x_ur_last];

% Ar*x = r solution
x_rr = Apinv*(P*r+ k_const*hr);
%x_rr_last = (1/n)*hr'*(r - Ar*x_rr);

x_r = [x_rr; 0];
    
% clock bias calculation
% Check if there is a real solution, if there is no real solution, the best
% result would be the local minimum or maximum (x = -b/(2a))
r1 = [r;0];
u1 = [u;1];
x_udr = x_u'*r1;
x_rdu = x_r'*u1;
x_udu = x_u'*u1;
x_rdr = x_rr'*r;

delta = (x_udr + x_rdu)^2 - 2*(1 + 2*x_rdr)*x_udu;

if delta <= 0
    cdt = (x_udr + x_rdu)/(2*(1 + 2*x_rdr));

elseif x_rdr < 0
    cdt = (x_udr + x_rdu + sqrt(delta))/(2*(1 + 2*x_rdr));
else
    cdt = (x_udr + x_rdu - sqrt(delta))/(2*(1 + 2*x_rdr));
end
% calculate final x vector
x_r = x_ur - 2*cdt*x_rr;

XR = XS*x_r;
dtR = cdt/c;
end


