function fuel = kerrFuel(tr,rc,cfg)
% KERRFUEL  Propellant for four instantaneous local relativistic burns.
% Burn 1: station departure      Burn 2: circular orbit insertion
% Burn 3: circular orbit escape  Burn 4: final docking
%
% The symmetric transfers make burns 1/4 and 2/3 equal in rapidity.
% This DOES NOT mean all possible Kerr trajectories are optimized.

stationMetric = kerrMetric(cfg.rStation,cfg.a);
% Station is assumed static in Boyer-Lindquist coordinates (rStation > 2).
uStation = [1/sqrt(-stationMetric(1,1)); 0; 0];
% Inward at departure (negative radial component); outward at docking.
% Both have the same rapidity relative to the stationary station.
uTransferStation = [tr.utStation; -tr.urStation; tr.uphiStation];
gamma1 = max(1,-uStation'*stationMetric*uTransferStation);
eta1 = acosh(gamma1);

circular = kerrCircular(rc,cfg.a);
metricOrbit = kerrMetric(rc,cfg.a);
uTransferOrbit = [tr.utPeri; 0; tr.uphiPeri];
uCircular = [circular.ut; 0; circular.uphi];
gamma2 = max(1,-uTransferOrbit'*metricOrbit*uCircular);
eta2 = acosh(gamma2);

fuel.rapidities = [eta1,eta2,eta2,eta1];
fuel.totalRapidity = sum(fuel.rapidities);

% Relativistic rocket equation for ideal constant exhaust velocity ve:
% m_initial/m_dry = exp((c/ve) * sum(delta_rapidity)).
exponent = (cfg.c/cfg.ve)*fuel.totalRapidity;
if exponent >= log(realmax/cfg.mDry)
    fuel.mInitial = Inf;
    fuel.mFuel = Inf;
    fuel.perBurn = Inf(1,4);
    return;
end
fuel.mInitial = cfg.mDry*exp(exponent);
fuel.mFuel = fuel.mInitial-cfg.mDry;

% Compute mass spent on each burn, working backward from final dry mass.
fuel.perBurn = zeros(1,4);
mAfter = cfg.mDry;
for i = 4:-1:1
    mBefore = mAfter*exp((cfg.c/cfg.ve)*fuel.rapidities(i));
    fuel.perBurn(i) = mBefore-mAfter;
    mAfter = mBefore;
end
end
