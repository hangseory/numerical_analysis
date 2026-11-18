function tr = kerrTransfer(rc,E,cfg,nSteps)
% KERRTRANSFER  Integrate one unpowered transfer leg from rc to station.
%
% Inputs: rc orbital insertion radius [GM/c^2]
%         E  transfer conserved specific energy
%         cfg black-hole and station parameters
%         nSteps number of equally spaced RK4 steps
% Output: tr contains r, phi, coordinate time t, proper time tau.
%
% CLASS CONNECTION: This is the same RK4 idea used in numerical ODEs.
% To avoid a singular slope at the radial turning point, integrate in
% s = sqrt(r-rc).  The inward path is the time reverse of this outward leg.
% In this RESTRICTED model, orbit insertion occurs at a radial turning point.

if nargin < 4, nSteps = cfg.nSteps; end
tr.ok = false;
tr.reason = 'Transfer could not be integrated.';
a = cfg.a;
rs = cfg.rStation;
if rc <= cfg.geom.horizon || rc >= rs || E <= 0, return; end

% At the radial turning point, (dr/dtau)^2 = 0.
% Solve that equation analytically for the positive angular momentum L.
A = E^2-1;
K = A*rc^3 + 2*rc^2 + a^2*A*rc + 2*a^2*E^2;
b = 4*a*E;
discriminant = b^2 + 4*(rc-2)*K;
if discriminant <= 0, return; end
L = 2*K/(b+sqrt(discriminant));
if ~isfinite(L) || L <= 0, return; end

% Factor of the radial potential remaining after removing (r-rc).
Q = @(r) A*r.^2 + (2+A*rc)*r + a^2*A-L^2+2*rc+A*rc^2;
checkR = linspace(rc,rs,30);
if any(Q(checkR) <= 0), return; end

% State vector y = [tau; t; phi], initially zero at orbital insertion.
sEnd = sqrt(rs-rc);
h = sEnd/nSteps;
s = (0:nSteps)'*h;
y = zeros(nSteps+1,3);

for i = 1:nSteps
    si = s(i);
    yi = y(i,:)';
    k1 = rate(si);
    k2 = rate(si+h/2);
    k3 = rate(si+h/2);
    k4 = rate(si+h);
    y(i+1,:) = (yi+(h/6)*(k1+2*k2+2*k3+k4))';
end

if any(~isfinite(y(:))) || y(end,2)<=0 || y(end,3)<=0, return; end

tr.ok = true;
tr.reason = 'OK';
tr.E = E; tr.L = L;
tr.r = rc+s.^2;
tr.tau = y(:,1);
tr.t = y(:,2);
tr.phi = y(:,3);
tr.tauHalf = y(end,1);
tr.tHalf = y(end,2);
tr.phiHalf = y(end,3);
tr.utStation = uTime(rs);
tr.uphiStation = uAngle(rs);
% Radial proper-time velocity at the station, from the Kerr radial potential.
tr.urStation = sqrt(max(0,(rs-rc)*Q(rs)/rs^3));
tr.utPeri = uTime(rc);
tr.uphiPeri = uAngle(rc);

    function derivative = rate(ss)
        rr = rc+ss^2;
        dTauDs = 2*rr^(3/2)/sqrt(Q(rr));
        derivative = [dTauDs; dTauDs*uTime(rr); dTauDs*uAngle(rr)];
    end
    function val = uTime(rr)
        delta = (rr-cfg.geom.horizon)*(rr-(1-sqrt(1-a^2)));
        val = ((rr^2+a^2+2*a^2/rr)*E-2*a*L/rr)/delta;
    end
    function val = uAngle(rr)
        delta = (rr-cfg.geom.horizon)*(rr-(1-sqrt(1-a^2)));
        val = ((1-2/rr)*L+2*a*E/rr)/delta;
    end
end
