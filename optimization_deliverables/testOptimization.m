function results = testOptimization()
% TESTOPTIMIZATION  Self-tests for the Optimization files (team member 2):
% goldenMin.m, kerrFuel.m, kerrMission.m, kerrOptimize.m.
% Follows the self-tests listed in the team specification (O1-O4, B.1).
%
% Run from any folder:  results = testOptimization
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','Gargantua_AnimationFix'));
cfg = optimizationCfg();
results = struct('name',{},'pass',{},'detail',{});

%% O3 goldenMin
[x,f] = goldenMin(@(x)(x-2).^2,0,5,60,1e-8);
results = add(results,'goldenMin (x-2)^2 on [0,5]', ...
    abs(x-2)<1e-6 && abs(f)<1e-10,sprintf('x=%.8f f=%.2e',x,f));
[x,f] = goldenMin(@(x)(x-3).^2+4,0,6,60,1e-8);
results = add(results,'goldenMin (x-3)^2+4 on [0,6]', ...
    abs(x-3)<1e-6 && abs(f-4)<1e-10,sprintf('x=%.8f f=%.8f',x,f));

%% O1 kerrFuel
% Zero-impulse mock: transfer velocity equals the static station velocity
% and the periapsis velocity equals the circular-orbit velocity.
rc = cfg.geom.isco+0.01;
orbit = kerrCircular(rc,cfg.a);
mock.utStation = 1/sqrt(1-2/cfg.rStation); mock.urStation = 0;
mock.uphiStation = 0; mock.utPeri = orbit.ut; mock.uphiPeri = orbit.uphi;
fuel = kerrFuel(mock,rc,cfg);
results = add(results,'kerrFuel: zero impulse gives zero fuel', ...
    all(fuel.rapidities<1e-6) && fuel.mFuel<1e-3*cfg.mDry, ...
    sprintf('eta=[%s] mFuel=%.3g kg',num2str(fuel.rapidities,3),fuel.mFuel));

%% O4 kerrOptimize at the GUI defaults
[best,info] = kerrOptimize(cfg);
results = add(results,'kerrOptimize: feasible candidate found',best.ok,best.reason);
if best.ok
    fuel = best.fuel;
    results = add(results,'kerrFuel: sum(perBurn) = mFuel', ...
        abs(sum(fuel.perBurn)-fuel.mFuel)<=1e-9*fuel.mFuel, ...
        sprintf('rel diff %.1e',abs(sum(fuel.perBurn)-fuel.mFuel)/fuel.mFuel));
    results = add(results,'kerrFuel: 4 finite, nonnegative rapidities', ...
        numel(fuel.rapidities)==4 && all(isfinite(fuel.rapidities)) && all(fuel.rapidities>=0) ...
        && fuel.mInitial>cfg.mDry,sprintf('eta=[%s]',num2str(fuel.rapidities,4)));

    % Four-velocities must stay timelike-normalised: u'*g*u = -1.
    tr = best.tr;
    gS = kerrMetric(cfg.rStation,cfg.a); uS = [tr.utStation;tr.urStation;tr.uphiStation];
    gP = kerrMetric(best.rc,cfg.a); uP = [tr.utPeri;0;tr.uphiPeri];
    uC = [best.circular.ut;0;best.circular.uphi];
    norms = [uS'*gS*uS, uP'*gP*uP, uC'*gP*uC];
    results = add(results,'4-velocity norm u''gu = -1', ...
        all(abs(norms+1)<1e-8),sprintf('[%s]',num2str(norms,10)));

    %% O2 kerrMission constraints on the accepted mission
    results = add(results,'kerrMission: time gain >= target', ...
        best.gainYears>=cfg.targetYears-1e-8,sprintf('%.6f yr',best.gainYears));
    results = add(results,'kerrMission: ship time <= limit', ...
        best.shipYears<=cfg.maxShipYears*(1+1e-10), ...
        sprintf('%.4f of %.4f days',best.shipYears*365.25,cfg.maxShipYears*365.25));
    results = add(results,'kerrMission: at least one revolution', ...
        best.circleRevs>=1,sprintf('%.6g revs',best.circleRevs));
    closure = mod(2*tr.phiHalf+best.circleAngle,2*pi);
    closure = min(closure,2*pi-closure);
    results = add(results,'kerrMission: station angular closure', ...
        closure<1e-6,sprintf('residual %.2e rad',closure));
    results = add(results,'kerrMission: never inside the horizon', ...
        min(best.r)>cfg.geom.horizon,sprintf('min r = %.8f, horizon = %.8f',min(best.r),cfg.geom.horizon));
    n = numel(best.r);
    sameLength = all(cellfun(@numel,{best.phi,best.t,best.tau,best.phase,best.x,best.y,best.shipDays,best.stationYearsVec})==n);
    results = add(results,'kerrMission: arrays same length, phase in {1,2,3}', ...
        sameLength && all(ismember(unique(best.phase),[1 2 3])),sprintf('%d samples',n));

    %% Numerical reliability of the optimum
    fine = kerrMission(best.rc,best.E,cfg,8*cfg.nSteps);
    rel = abs(fine.shipYears-best.shipYears)/fine.shipYears;
    results = add(results,'RK4: ship time stable under 4x more steps', ...
        fine.ok && rel<1e-4,sprintf('rel change %.1e',rel));

    dense = cfg; dense.nRadiusSamples = 2*cfg.nRadiusSamples;
    [best2,~] = kerrOptimize(dense);
    rel = abs(best2.fuel.mFuel-best.fuel.mFuel)/best.fuel.mFuel;
    results = add(results,'Optimum independent of rc grid density (x2)', ...
        best2.ok && rel<1e-3,sprintf('fuel %.6g vs %.6g kg (rel %.1e)',best.fuel.mFuel,best2.fuel.mFuel,rel));

    % Bisection assumption: transfer existence switches only once in E.
    Es = linspace(sqrt(1-2/cfg.rStation),cfg.Emax,400);
    exists = arrayfun(@(E) kerrTransfer(best.rc,E,cfg,cfg.searchSteps).ok,Es);
    switches = nnz(diff(exists));
    results = add(results,'Bisection assumption: one feasibility switch in E', ...
        switches==1 && ~exists(1) && exists(end),sprintf('%d switch(es) over 400 samples',switches));
    results = add(results,'Chosen E sits just above Ecrit', ...
        best.E>=interp1(info.radii,info.Ecrit,best.rc,'linear','extrap')-1e-6, ...
        sprintf('E = %.10f',best.E));
end

%% No-solution handling
impossible = cfg; impossible.targetYears = 1e6;
[none,~] = kerrOptimize(impossible);
results = add(results,'Impossible target returns ok=false with reason', ...
    ~none.ok && ~isempty(none.reason),none.reason);

%% Report
fprintf('\n%-55s %s\n','TEST','RESULT');
for i = 1:numel(results)
    if results(i).pass, s='PASS'; else, s='FAIL'; end
    fprintf('%-55s %s   %s\n',results(i).name,s,results(i).detail);
end
fprintf('\n%d / %d passed\n',nnz([results.pass]),numel(results));
end

function results = add(results,name,pass,detail)
results(end+1) = struct('name',name,'pass',logical(pass),'detail',detail);
end
