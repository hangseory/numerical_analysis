function [best,info] = kerrOptimize(cfg)
% KERROPTIMIZE  Search for minimum fuel among feasible prograde missions.
%
% CLASS METHODS: Bisection (lowest usable transfer energy), finite grid
% over rc (robust initial candidate), then Golden-section search
% (goldenMin.m) in a feasible local bracket.
%
% Fuel grows with the transfer energy E, so for each circular radius rc the
% best E is the LOWEST energy that still gives a feasible mission:
%   1) Ecrit(rc): lowest E for which the transfer rc -> station exists
%      (below it the ship cannot climb back out to the station).
%   2) Starting at Ecrit + energyMargin, the lowest E that also meets the
%      ship-time limit (ship time shrinks as E grows).
% Both are found by Bisection, so E is no longer tied to a coarse E grid and
% the outer search is one-dimensional in rc.
% The result is the BEST FOUND, not a proven global optimum.

% Settings added for the Bisection step; defaults keep main.m unchanged.
cfg = withDefault(cfg,'energyMargin',1e-5);       % E offset above Ecrit
cfg = withDefault(cfg,'energyTolerance',1e-10);   % Bisection stop width
cfg = withDefault(cfg,'convergenceTolerance',1e-3); % nSteps vs 2*nSteps

best.ok = false;
best.reason = 'No feasible candidate in the tested search domain.';
info.evaluated=0;
info.coarseFeasible=0;
info.costHistory=[];
info.transferEvaluations=0;

% A ship at rest at the station has E = sqrt(1-2/rStation); any transfer
% that reaches the station must have at least this energy.
Elow = sqrt(1-2/cfg.rStation);
if Elow >= cfg.Emax
    best.reason = 'Energy search interval is empty.';
    return;
end
rMin = cfg.geom.isco+cfg.iscoMargin;
rMax = cfg.rStation*cfg.maxOrbitFraction;
if rMin >= rMax, return; end

% Log-spaced radii give more samples near the ISCO where D grows rapidly.
radii = cfg.geom.isco+logspace(log10(rMin-cfg.geom.isco), ...
    log10(rMax-cfg.geom.isco),cfg.nRadiusSamples);
costs = inf(size(radii));
info.radii = radii;
info.Ecrit = nan(size(radii));
info.Ebest = nan(size(radii));

for j = 1:length(radii)
    [coarse,Ecrit] = bestMissionAt(radii(j),cfg.searchSteps);
    info.Ecrit(j) = Ecrit;
    if coarse.ok
        info.coarseFeasible=info.coarseFeasible+1;
        info.Ebest(j) = coarse.E;
        costs(j)=coarse.fuel.mFuel;
        if ~best.ok || costs(j)<best.fuel.mFuel
            % Recompute using finer steps before accepting the candidate.
            exact=acceptCandidate(radii(j),coarse.E);
            if exact.ok && (~best.ok || exact.fuel.mFuel<best.fuel.mFuel)
                best=exact;
                info.costHistory(end+1)=exact.fuel.mFuel;
            end
        end
    end
end
info.coarseCost = costs;
fprintf('Radius grid completed: %d / %d radii feasible.\n', ...
    info.coarseFeasible,length(radii));

% Refine the bracket around the grid's best point. A neighbour may be
% infeasible (Inf): the optimum then lies at the ship-time limit, and
% Golden-section still closes in on it from the feasible side.
[bestCost,index]=min(costs);
if isfinite(bestCost)
    lo=radii(max(index-1,1));hi=radii(min(index+1,length(radii)));
    info.goldenBracket=[lo hi];
    info.goldenX=[]; info.goldenCost=[];  % every Golden-section evaluation
    functionToMinimize=@(r) candidateCost(r);
    [rStar,~]=goldenMin(functionToMinimize,lo,hi, ...
        cfg.goldenIterations,cfg.radiusTolerance);
    [refined,~]=bestMissionAt(rStar,cfg.searchSteps);
    if refined.ok
        exact=acceptCandidate(rStar,refined.E);
        if exact.ok && (~best.ok || exact.fuel.mFuel<best.fuel.mFuel)
            best=exact;
            info.costHistory(end+1)=exact.fuel.mFuel;
        end
    end
    fprintf('Golden-section refinement completed.\n');
end

    function [m,Ecrit] = bestMissionAt(rc,nSteps)
        % Lowest-fuel feasible mission at a fixed rc (two Bisections).
        m.ok = false;
        m.reason = 'No transfer energy found.';
        transferExists = @(E) countTransfer(rc,E);
        Ecrit = lowestTrue(transferExists,Elow,cfg.Emax);
        if isnan(Ecrit), return; end
        E0 = min(Ecrit+cfg.energyMargin,cfg.Emax);
        missionOk = @(E) countMission(rc,E,nSteps);
        E = lowestTrue(missionOk,E0,cfg.Emax);
        if isnan(E), return; end
        m = kerrMission(rc,E,cfg,nSteps);
        info.evaluated = info.evaluated+1;
    end

    function E = lowestTrue(test,lo,hi)
        % BISECTION: smallest E in [lo,hi] with test(E) true, assuming
        % test is false below some threshold and true above it.
        if test(lo), E = lo; return; end
        if ~test(hi), E = NaN; return; end
        while hi-lo > cfg.energyTolerance
            mid = (lo+hi)/2;
            if test(mid), hi = mid; else, lo = mid; end
        end
        E = hi;
    end

    function ok = countTransfer(rc,E)
        tr = kerrTransfer(rc,E,cfg,cfg.searchSteps);
        info.transferEvaluations = info.transferEvaluations+1;
        ok = tr.ok;
    end

    function ok = countMission(rc,E,nSteps)
        % (Names differ from the parent's variables: nested functions share them.)
        trial = kerrMission(rc,E,cfg,nSteps);
        info.evaluated = info.evaluated+1;
        ok = trial.ok;
    end

    function exact = acceptCandidate(rc,E)
        % Accept only if doubling the RK4 steps leaves the times unchanged.
        exact = kerrMission(rc,E,cfg,cfg.nSteps);
        check = kerrMission(rc,E,cfg,2*cfg.nSteps);
        info.evaluated = info.evaluated+2;
        if ~exact.ok || ~check.ok
            exact.ok = false;
            exact.reason = 'Candidate changed feasibility under step refinement.';
            return;
        end
        tol = cfg.convergenceTolerance;
        if abs(exact.shipYears-check.shipYears) > tol*check.shipYears || ...
                abs(exact.gainYears-check.gainYears) > tol*check.gainYears
            exact.ok = false;
            exact.reason = 'RK4 times not converged at this energy.';
            return;
        end
        exact = check;
    end

    function cost = candidateCost(r)
        % Objective-function wrapper, similar to obj.m in the class examples.
        [m,~]=bestMissionAt(r,cfg.searchSteps);
        if m.ok
            cost=m.fuel.mFuel;
        else
            cost=Inf;  % Infeasible candidates must not win the search.
        end
        info.goldenX(end+1)=r;
        info.goldenCost(end+1)=cost;
    end
end

function cfg = withDefault(cfg,name,value)
if ~isfield(cfg,name), cfg.(name) = value; end
end
