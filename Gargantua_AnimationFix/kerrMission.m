function m = kerrMission(rc,E,cfg,nSteps)
% KERRMISSION  Evaluate ONE candidate circular-orbit mission.
%
% The chosen family is deliberately simple:
%   - approach and return are symmetric free-fall geodesic legs;
%   - insertion occurs at the inward transfer's turning point;
%   - spacecraft performs at least one full prograde circular revolution;
%   - circle departure phase is chosen for exact angular station closure;
%   - fourth burn stops the craft relative to the stationary station.
%
% r_c and E are the TWO outer search variables.
% The orbital residence time is calculated from the station-return condition.

if nargin < 4, nSteps = cfg.nSteps; end
m.ok = false;
m.reason = 'Candidate does not satisfy mission constraints.';
m.rc = rc; m.E = E;
if rc <= cfg.geom.isco+cfg.iscoMargin || rc >= cfg.rStation, return; end
tr = kerrTransfer(rc,E,cfg,nSteps);
if ~tr.ok, m.reason = tr.reason; return; end
orbit = kerrCircular(rc,cfg.a);

% A stationary clock at the station runs at sqrt(1-2/rStation) * dt.
stationRate = sqrt(1-2/cfg.rStation);
% Per unit circular angle, calculate station-time gain minus ship-time.
gainPerRadian = (stationRate-1/orbit.D)/orbit.Omega;
if gainPerRadian <= 0, return; end

% Both transfer legs contribute to the total mission time difference.
transferGain = 2*(stationRate*tr.tHalf-tr.tauHalf);
targetGain = cfg.targetYears*cfg.yearSeconds/cfg.tUnit;
angleNeeded = max(2*pi,(targetGain-transferGain)/gainPerRadian);
if ~isfinite(angleNeeded), return; end

% For the station to be at the SAME angular position after return:
% approach_angle + circle_angle + return_angle = 2*pi*k.
% Choose the smallest integer k that meets the time and 1-orbit requirements.
k = ceil((2*tr.phiHalf+angleNeeded)/(2*pi)-1e-12);
circleAngle = 2*pi*k-2*tr.phiHalf;
if circleAngle < 2*pi-1e-9, return; end

% Total elapsed time in natural units G=c=M=1.
tCircle = circleAngle/orbit.Omega;
tauCircle = tCircle/orbit.D;
tCoord = 2*tr.tHalf+tCircle;
tShip = 2*tr.tauHalf+tauCircle;
tStation = stationRate*tCoord;
timeGain = tStation-tShip;

shipYears = tShip*cfg.tUnit/cfg.yearSeconds;
gainYears = timeGain*cfg.tUnit/cfg.yearSeconds;
if shipYears > cfg.maxShipYears*(1+1e-10), return; end
if gainYears < cfg.targetYears-1e-8, return; end

fuel = kerrFuel(tr,rc,cfg);
if ~isfinite(fuel.mFuel) || fuel.mFuel < 0, return; end

m.ok = true;
m.reason = 'Feasible within the restricted trajectory model';
m.tr = tr;
m.fuel = fuel;
m.circular = orbit;
m.totalWinding = k;
m.circleAngle = circleAngle;
m.circleRevs = circleAngle/(2*pi);
m.tShip = tShip;
m.tStation = tStation;
m.shipYears = shipYears;
m.stationYears = tStation*cfg.tUnit/cfg.yearSeconds;
m.gainYears = gainYears;
m.costUSD = fuel.mFuel*cfg.fuelPriceUSDperKg;

% Plotting/animation data. NEVER numerically integrate hundreds of thousands
% of orbital revolutions for display. Store enough points for one circle.
rIn = flipud(tr.r);
phiIn = tr.phiHalf-flipud(tr.phi);
tIn = tr.tHalf-flipud(tr.t);
tauIn = tr.tauHalf-flipud(tr.tau);

nCircle = 300;
f = linspace(0,1,nCircle)';
rCircle = rc+zeros(nCircle,1);
phiCircle = tr.phiHalf+circleAngle*f;
tCircleVec = tr.tHalf+tCircle*f;
tauCircleVec = tr.tauHalf+tauCircle*f;

m.r = [rIn; rCircle(2:end); tr.r(2:end)];
m.phi = [phiIn; phiCircle(2:end); tr.phiHalf+circleAngle+tr.phi(2:end)];
m.t = [tIn; tCircleVec(2:end); tr.tHalf+tCircle+tr.t(2:end)];
m.tau = [tauIn; tauCircleVec(2:end); tr.tauHalf+tauCircle+tr.tau(2:end)];
m.phase = [ones(length(rIn),1);2*ones(nCircle-1,1);3*ones(length(tr.r)-1,1)];
m.x = m.r.*cos(m.phi);
m.y = m.r.*sin(m.phi);
m.shipDays = m.tau*cfg.tUnit/86400;
m.stationYearsVec = m.t*stationRate*cfg.tUnit/cfg.yearSeconds;
end
