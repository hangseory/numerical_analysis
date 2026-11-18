function cfg = optimizationCfg(targetYears,maxShipDays)
% OPTIMIZATIONCFG  Same settings as missionSettings() in main.m, for running
% the solver without the GUI. Keep in sync with main.m if the team changes it.
if nargin < 1, targetYears = 100; end
if nargin < 2, maxShipDays = 30.4375; end
cfg.Msolar=1e8;
cfg.a=1-1e-14;
cfg.mDry=100000;
cfg.c=299792458;
cfg.ve=0.15*cfg.c;
cfg.rStation=40;
cfg.fuelPriceUSDperKg=100;

cfg.G=6.67430e-11;
cfg.Msun=1.98847e30;
cfg.yearSeconds=365.25*86400;
cfg.tUnit=cfg.G*(cfg.Msolar*cfg.Msun)/cfg.c^3;
cfg.rUnit=cfg.G*(cfg.Msolar*cfg.Msun)/cfg.c^2;
cfg.geom=kerrGeometry(cfg.a);

cfg.nEnergySamples=14;
cfg.nRadiusSamples=48;
cfg.Emax=1.10;
cfg.minEnergyMargin=0.002;
cfg.iscoMargin=5e-4;
cfg.maxOrbitFraction=0.75;
cfg.searchSteps=350;
cfg.nSteps=1500;
cfg.goldenIterations=18;
cfg.radiusTolerance=1e-9;
cfg.outputDir=fullfile(pwd,'results');

cfg.targetYears=targetYears;
cfg.maxShipYears=maxShipDays/365.25;
end
