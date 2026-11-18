function [best,info] = kerrOptimize(cfg)
% KERROPTIMIZE  Search for minimum fuel among feasible prograde missions.
%
% CLASS METHODS: finite grid (for a robust initial candidate), then
% Golden-section search (goldenMin.m) in a feasible local bracket.
%
% The two search variables are transfer energy E and circular radius rc.
% We search a GRID of energies, not an arbitrary multivariable optimizer.
% Thus the result is the BEST FOUND, not a proven global optimum.

best.ok = false;
best.reason = 'No feasible candidate in the tested search domain.';
info.evaluated=0;
info.coarseFeasible=0;
info.costHistory=[];

Emin = sqrt(1-2/cfg.rStation)+cfg.minEnergyMargin;
if Emin >= cfg.Emax
    best.reason = 'Energy search interval is empty.';
    return;
end
energies = linspace(Emin,cfg.Emax,cfg.nEnergySamples);
rMin = cfg.geom.isco+cfg.iscoMargin;
rMax = cfg.rStation*cfg.maxOrbitFraction;
if rMin >= rMax, return; end

% Log-spaced radii give more samples near the ISCO where D grows rapidly.
radii = cfg.geom.isco+logspace(log10(rMin-cfg.geom.isco), ...
    log10(rMax-cfg.geom.isco),cfg.nRadiusSamples);

for i = 1:length(energies)
    E=energies(i);
    costs=inf(size(radii));

    for j = 1:length(radii)
        m=kerrMission(radii(j),E,cfg,cfg.searchSteps);
        info.evaluated=info.evaluated+1;
        if m.ok
            info.coarseFeasible=info.coarseFeasible+1;
            costs(j)=m.fuel.mFuel;
            if ~best.ok || costs(j)<best.fuel.mFuel
                % Recompute using finer steps before accepting the candidate.
                exact=kerrMission(radii(j),E,cfg,cfg.nSteps);
                if exact.ok && (~best.ok || exact.fuel.mFuel<best.fuel.mFuel)
                    best=exact;
                    info.costHistory(end+1)=exact.fuel.mFuel; %#ok<AGROW>
                end
            end
        end
    end

    % Refine a locally feasible bracket around the grid's best point.
    [~,index]=min(costs);
    if index>1 && index<length(radii) && ...
            all(isfinite(costs(index-1:index+1)))
        lo=radii(index-1);hi=radii(index+1);
        functionToMinimize=@(r) candidateCost(r,E,cfg);
        [rStar,~]=goldenMin(functionToMinimize,lo,hi, ...
            cfg.goldenIterations,cfg.radiusTolerance);
        exact=kerrMission(rStar,E,cfg,cfg.nSteps);
        if exact.ok && (~best.ok || exact.fuel.mFuel<best.fuel.mFuel)
            best=exact;
            info.costHistory(end+1)=exact.fuel.mFuel; %#ok<AGROW>
        end
    end
    fprintf('Energy sample %2d / %2d completed.\n',i,length(energies));
end
end

function cost = candidateCost(r,E,cfg)
% Objective-function wrapper, similar to obj.m in the class examples.
m=kerrMission(r,E,cfg,cfg.searchSteps);
if m.ok
    cost=m.fuel.mFuel;
else
    cost=Inf;  % Infeasible candidates must not win the search.
end
end
