function makeOptimizationFigures()
% MAKEOPTIMIZATIONFIGURES  Presentation figures and result tables for the
% Optimization part (team member 2). Writes PNGs to ./figures and tables to
% ./results.  Run from any folder:  makeOptimizationFigures
here = fileparts(mfilename('fullpath'));
codeDir = fullfile(here,'..','Gargantua_AnimationFix');
addpath(codeDir);
figDir = fullfile(here,'figures'); resDir = fullfile(here,'results');
if ~exist(figDir,'dir'), mkdir(figDir); end
if ~exist(resDir,'dir'), mkdir(resDir); end

blue = hex('#2a78d6'); orange = hex('#eb6834'); gray = hex('#9a9893');
ink = hex('#0b0b0b'); ink2 = hex('#52514e');

cfg = optimizationCfg(100,30.4375);
[best,info] = kerrOptimize(cfg);
assert(best.ok,'Baseline optimisation failed: %s',best.reason);
margin = 1e-5;  % same energyMargin default as kerrOptimize

%% Figure 1: why the optimum sits on the ship-time limit
radii = cfg.geom.isco+logspace(log10(cfg.iscoMargin),log10(0.05),60);
fuelR = nan(size(radii)); shipR = nan(size(radii));
open = cfg; open.maxShipYears = Inf;     % show the curve past the limit
for j = 1:numel(radii)
    Ec = criticalEnergy(radii(j),cfg);
    if isnan(Ec), continue; end
    m = kerrMission(radii(j),Ec+margin,open,cfg.nSteps);
    if m.ok, fuelR(j) = m.fuel.mFuel; shipR(j) = m.shipYears*365.25; end
end
x = radii-cfg.geom.isco; xBest = best.rc-cfg.geom.isco;
limitDays = cfg.maxShipYears*365.25;
f = newFigure(900,640);
t = tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');
ax = nexttile(t); styleAxes(ax,ink2);
plot(ax,x,fuelR/1e6,'-','Color',blue,'LineWidth',2); set(ax,'XScale','log');
plot(ax,xBest,best.fuel.mFuel/1e6,'o','MarkerSize',9,'MarkerFaceColor',orange,'MarkerEdgeColor','w','LineWidth',1.5);
text(ax,xBest,best.fuel.mFuel/1e6,sprintf('  optimum: %.2f million kg',best.fuel.mFuel/1e6),'Color',ink,'FontSize',11,'VerticalAlignment','bottom');
ylabel(ax,'Propellant [10^6 kg]'); title(ax,'Propellant falls as r_c moves out from the ISCO','Color',ink);
ax.XTickLabel = {};
ax2 = nexttile(t); styleAxes(ax2,ink2);
plot(ax2,x,shipR,'-','Color',blue,'LineWidth',2); set(ax2,'XScale','log','YScale','log');
yline(ax2,limitDays,'--','Color',ink2,'LineWidth',1.2);
text(ax2,1.05*x(1),1.18*limitDays,sprintf('ship-time limit %.2f d',limitDays),'Color',ink2,'FontSize',10);
plot(ax2,xBest,best.shipYears*365.25,'o','MarkerSize',9,'MarkerFaceColor',orange,'MarkerEdgeColor','w','LineWidth',1.5);
ylabel(ax2,'Ship time [days, log scale]'); xlabel(ax2,'r_c - r_{ISCO}  [r_g]');
title(ax2,'...but ship time grows, so the limit decides r_c','Color',ink);
linkaxes([ax ax2],'x');
title(t,sprintf('Target: %g years gained, ship time \\leq %.2f days  (E = E_{crit}+10^{-5})',cfg.targetYears,limitDays),'FontSize',13,'Color',ink);
saveFigure(f,fullfile(figDir,'fig1_fuel_and_shiptime_vs_rc.png'));

%% Figure 2: fuel vs transfer energy at the optimum radius
Ec = criticalEnergy(best.rc,cfg);
Es = linspace(Ec-0.002,Ec+0.012,500);
fuelE = nan(size(Es));
for i = 1:numel(Es)
    m = kerrMission(best.rc,Es(i),open,cfg.searchSteps);
    if m.ok, fuelE(i) = m.fuel.mFuel; end
end
f = newFigure(900,480); ax = axes(f); styleAxes(ax,ink2); hold(ax,'on');
yl = [0 1.05*max(fuelE,[],'omitnan')/1e6];
patch(ax,[Es(1) Ec Ec Es(1)],[yl(1) yl(1) yl(2) yl(2)],gray,'FaceAlpha',0.18,'EdgeColor','none');
text(ax,Es(1)+0.0001,0.9*yl(2),{'No transfer','exists'},'Color',ink2,'FontSize',10);
plot(ax,Es,fuelE/1e6,'-','Color',blue,'LineWidth',2);
xline(ax,Ec,'-','Color',ink2,'LineWidth',1,'Label','E_{crit} (Bisection)','FontSize',10,'LabelVerticalAlignment','middle');
plot(ax,best.E,best.fuel.mFuel/1e6,'o','MarkerSize',9,'MarkerFaceColor',orange,'MarkerEdgeColor','w','LineWidth',1.5);
text(ax,best.E,best.fuel.mFuel/1e6,'  chosen E','Color',ink,'FontSize',11,'VerticalAlignment','top');
ylim(ax,yl); xlim(ax,[Es(1) Es(end)]);
xlabel(ax,'Transfer energy E (per unit mass)'); ylabel(ax,'Propellant [10^6 kg]');
title(ax,sprintf('At r_c = %.6f r_g, the lowest feasible energy needs the least propellant',best.rc),'Color',ink);
saveFigure(f,fullfile(figDir,'fig2_fuel_vs_energy.png'));

%% Figure 3: Golden-section convergence
gx = info.goldenX; gc = info.goldenCost;
f = newFigure(900,600);
t = tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');
ax = nexttile(t); styleAxes(ax,ink2); hold(ax,'on');
k = 0:cfg.goldenIterations;
width0 = diff(info.goldenBracket);
plot(ax,k,width0*((sqrt(5)-1)/2).^k,'-o','Color',blue,'LineWidth',2,'MarkerFaceColor',blue,'MarkerSize',5);
set(ax,'YScale','log');
ylabel(ax,'Bracket width [r_g]'); title(ax,'Golden-section: the bracket shrinks by 0.618 each iteration','Color',ink);
ax2 = nexttile(t); styleAxes(ax2,ink2); hold(ax2,'on');
feasible = isfinite(gc);
plot(ax2,find(feasible),gx(feasible)-cfg.geom.isco,'o','Color',blue,'MarkerFaceColor',blue,'MarkerSize',7,'DisplayName','feasible');
plot(ax2,find(~feasible),gx(~feasible)-cfg.geom.isco,'x','Color',ink2,'MarkerSize',9,'LineWidth',1.5,'DisplayName','infeasible (ship time over limit)');
yline(ax2,best.rc-cfg.geom.isco,'--','Color',orange,'LineWidth',1.5,'DisplayName','final r_c');
xlabel(ax2,'Function evaluation'); ylabel(ax2,'r_c - r_{ISCO} [r_g]');
legend(ax2,'Location','northeast','Box','off');
title(ax2,'Evaluated radii converge on the optimum from alternating sides','Color',ink);
saveFigure(f,fullfile(figDir,'fig3_golden_section_convergence.png'));

%% Scenarios: new optimiser vs the original E-grid optimiser
scen = [100 30.4375; 10 365.25; 1000 365.25; 1 7];
names = {'100 yr / 30.4 d','10 yr / 1 yr','1000 yr / 1 yr','1 yr / 7 d'};
oldDir = prepareOldCode(here);
rows = cell(size(scen,1),1);
for s = 1:size(scen,1)
    c = optimizationCfg(scen(s,1),scen(s,2));
    tic; [bn,in] = evalcSilent(@() kerrOptimize(c)); tn = toc;
    cd(oldDir); clear kerrOptimize kerrFuel
    tic; [bo,~] = evalcSilent(@() kerrOptimize(c)); to = toc;
    cd(here); clear kerrOptimize kerrFuel
    rows{s} = struct('name',names{s},'target',scen(s,1),'maxDays',scen(s,2), ...
        'new',bn,'old',bo,'tNew',tn,'tOld',to,'evals',in.evaluated);
end
rows = [rows{:}];

% Figure 4: propellant, original vs improved
f = newFigure(900,480); ax = axes(f); styleAxes(ax,ink2); hold(ax,'on');
vals = nan(numel(rows),2);
for s = 1:numel(rows)
    if rows(s).old.ok, vals(s,1) = rows(s).old.fuel.mFuel/1e6; end
    if rows(s).new.ok, vals(s,2) = rows(s).new.fuel.mFuel/1e6; end
end
b = bar(ax,vals,'grouped','BarWidth',0.7,'EdgeColor','none');
b(1).FaceColor = gray; b(2).FaceColor = blue;
for s = 1:numel(rows)
    if all(isfinite(vals(s,:)))
        text(ax,s+0.15,vals(s,2),sprintf('%+.1f%%',100*(vals(s,2)/vals(s,1)-1)), ...
            'HorizontalAlignment','center','VerticalAlignment','bottom','Color',ink,'FontSize',11,'FontWeight','bold');
    end
end
set(ax,'XTick',1:numel(rows),'XTickLabel',names);
ylabel(ax,'Propellant [10^6 kg]'); xlabel(ax,'Target time gain / ship-time limit');
legend(ax,{'Original: E grid + Golden','Improved: Bisection on E + Golden'},'Location','northoutside','Orientation','horizontal','Box','off');
title(ax,'Bisection on the transfer energy lowers the propellant in every case','Color',ink);
saveFigure(f,fullfile(figDir,'fig4_original_vs_improved.png'));

%% Tables
fid = fopen(fullfile(resDir,'optimization_scenarios.csv'),'w');
fprintf(fid,'Scenario,Target gain (yr),Max ship time (d),Feasible,r_c (r_g),E,Circular revolutions,Ship time (d),Time gained (yr),Propellant (kg),Propellant original (kg),Change (%%),Cost (USD),Burn rapidities,Runtime (s)\n');
md = {'| Scenario | r_c [r_g] | E | Revolutions | Ship time [d] | Gain [yr] | Propellant [kg] | Original [kg] | Change |', ...
      '|---|---|---|---|---|---|---|---|---|'};
for s = 1:numel(rows)
    r = rows(s); n = r.new;
    if n.ok
        oldFuel = NaN; if r.old.ok, oldFuel = r.old.fuel.mFuel; end
        change = 100*(n.fuel.mFuel/oldFuel-1);
        fprintf(fid,'%s,%g,%g,yes,%.10f,%.10f,%.6g,%.6f,%.6f,%.6g,%.6g,%.2f,%.6g,%s,%.1f\n', ...
            r.name,r.target,r.maxDays,n.rc,n.E,n.circleRevs,n.shipYears*365.25,n.gainYears, ...
            n.fuel.mFuel,oldFuel,change,n.costUSD,num2str(n.fuel.rapidities,5),r.tNew);
        md{end+1} = sprintf('| %s | %.6f | %.6f | %.4g | %.2f | %.2f | %.4g | %.4g | %+.1f%% |', ...
            r.name,n.rc,n.E,n.circleRevs,n.shipYears*365.25,n.gainYears,n.fuel.mFuel,oldFuel,change); %#ok<AGROW>
    else
        fprintf(fid,'%s,%g,%g,no,,,,,,,,,,,%.1f\n',r.name,r.target,r.maxDays,r.tNew);
        md{end+1} = sprintf('| %s | no feasible mission | | | | | | | |',r.name); %#ok<AGROW>
    end
end
fclose(fid);
fid = fopen(fullfile(resDir,'optimization_scenarios.md'),'w');
fprintf(fid,'%s\n',md{:}); fclose(fid);
fprintf('%s\n',md{:});
fprintf('Baseline: rc=%.10f E=%.10f fuel=%.6g kg, golden evaluations=%d, missions=%d, transfers=%d\n', ...
    best.rc,best.E,best.fuel.mFuel,numel(info.goldenX),info.evaluated,info.transferEvaluations);
end

function Ec = criticalEnergy(rc,cfg)
% Same Bisection as kerrOptimize: lowest E with an existing transfer.
lo = sqrt(1-2/cfg.rStation); hi = cfg.Emax;
if ~kerrTransfer(rc,hi,cfg,cfg.searchSteps).ok, Ec = NaN; return; end
while hi-lo > 1e-10
    mid = (lo+hi)/2;
    if kerrTransfer(rc,mid,cfg,cfg.searchSteps).ok, hi = mid; else, lo = mid; end
end
Ec = hi;
end

function oldDir = prepareOldCode(here)
% The original optimiser and fuel files, renamed so they shadow the new ones
% when MATLAB's current folder is oldDir.
oldDir = fullfile(tempdir,'gargantua_original_optimizer');
if ~exist(oldDir,'dir'), mkdir(oldDir); end
backup = fullfile(here,'original_code');
copyfile(fullfile(backup,'kerrOptimize_original_20261111.m'),fullfile(oldDir,'kerrOptimize.m'));
copyfile(fullfile(backup,'kerrFuel_original_20261111.m'),fullfile(oldDir,'kerrFuel.m'));
end

function [b,info] = evalcSilent(fun)
[~,b,info] = evalc('fun()');
end

function f = newFigure(w,h)
f = figure('Visible','off','Color',hex('#fcfcfb'),'Position',[100 100 w h]);
end

function styleAxes(ax,ink2)
set(ax,'Color','none','Box','off','FontSize',11,'XColor',ink2,'YColor',ink2, ...
    'GridColor',[0.85 0.85 0.83],'GridAlpha',1,'TickDir','out');
grid(ax,'on'); hold(ax,'on');   % keep this styling when plotting
end

function saveFigure(f,file)
exportgraphics(f,file,'Resolution',200);
close(f);
end

function c = hex(s)
c = sscanf(s(2:end),'%2x%2x%2x',[1 3])/255;
end
