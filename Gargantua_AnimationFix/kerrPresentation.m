function kerrPresentation(m,cfg)
% KERRPRESENTATION
% Animated mission presentation with:
%   1) full mission view,
%   2) black-hole close-up,
%   3) approach panel,
%   4) circular-orbit panel,
%   5) return panel.
%
% The trajectory is built progressively as the spacecraft moves. Approach
% and return are shown more slowly than before.

if ~m.ok
    error('Cannot animate an infeasible mission.');
end

% ----------------------- Figure setup -----------------------
screen = get(groot,'ScreenSize');
windowW = min(1500,max(980,screen(3)-80));
windowH = min(860,max(650,screen(4)-140));
windowX = screen(1)+max(10,floor((screen(3)-windowW)/2));
windowY = screen(2)+max(45,floor((screen(4)-windowH)/2));
fig = figure('Name','GARGANTUA | Dual View + Phase Panels', ...
    'Color',[0.965 0.976 0.988], ...
    'Position',[windowX windowY windowW windowH], ...
    'CloseRequestFcn',@stopAndClose);
setappdata(fig,'StopPlayback',false);

blue   = [0.12 0.40 0.83];
green  = [0.10 0.61 0.42];
orange = [0.90 0.39 0.17];
red    = [0.79 0.13 0.26];

% ----------------------- Precompute display paths -----------------------
idsApp = find(m.phase==1);
idsOrb = find(m.phase==2);
idsRet = find(m.phase==3);

[xApp,yApp] = polarPlotSamples(m.r(idsApp),m.phi(idsApp));
[xRet,yRet] = polarPlotSamples(m.r(idsRet),m.phi(idsRet));

% One representative visible circular revolution.
thetaOrb = linspace(m.phi(idsOrb(1)), m.phi(idsOrb(1))+2*pi, 1200);
xOrb = m.rc*cos(thetaOrb);
yOrb = m.rc*sin(thetaOrb);

% Burn locations
idxIn = find(m.phase==1,1,'last');
idxCircle = find(m.phase==2,1,'last');
b1 = [cfg.rStation,0];
b2 = [m.x(idxIn),m.y(idxIn)];
b3 = [m.x(idxCircle),m.y(idxCircle)];
b4 = [cfg.rStation,0];

% ----------------------- Main axes -----------------------
axFull = axes('Parent',fig,'Units','normalized','Position',[0.04 0.56 0.34 0.34]);
drawMissionBackground(axFull,m,cfg,'full',b1,b2,b3,b4);
title(axFull,'FULL MISSION','FontSize',12);
hold(axFull,'on');
appTrailFull = plot(axFull,nan,nan,'Color',blue,'LineWidth',1.8,'HandleVisibility','off');
orbTrailFull = plot(axFull,nan,nan,'Color',green,'LineWidth',3.2,'HandleVisibility','off');
retTrailFull = plot(axFull,nan,nan,'Color',orange,'LineWidth',1.8,'HandleVisibility','off');
shipFull = plot(axFull,cfg.rStation,0,'o','MarkerSize',10, ...
    'MarkerFaceColor',[0.89 0.22 0.25],'MarkerEdgeColor',[0.27 0.12 0.15], ...
    'HandleVisibility','off');

axClose = axes('Parent',fig,'Units','normalized','Position',[0.42 0.56 0.34 0.34]);
drawMissionBackground(axClose,m,cfg,'zoom',b1,b2,b3,b4);
title(axClose,'BLACK HOLE CLOSE-UP','FontSize',12);
hold(axClose,'on');
appTrailClose = plot(axClose,nan,nan,'Color',blue,'LineWidth',2.1,'HandleVisibility','off');
orbTrailClose = plot(axClose,nan,nan,'Color',green,'LineWidth',3.8,'HandleVisibility','off');
retTrailClose = plot(axClose,nan,nan,'Color',orange,'LineWidth',2.1,'HandleVisibility','off');
shipClose = plot(axClose,nan,nan,'o','MarkerSize',11, ...
    'MarkerFaceColor',[0.89 0.22 0.25],'MarkerEdgeColor',[0.27 0.12 0.15], ...
    'HandleVisibility','off');

% ----------------------- Phase panels -----------------------
axApp = axes('Parent',fig,'Units','normalized','Position',[0.05 0.14 0.21 0.25]);
drawPhaseBackground(axApp,m,cfg,1,'APPROACH',blue,b1,b2,b3,b4);
hold(axApp,'on');
appTrailPanel = plot(axApp,nan,nan,'Color',blue,'LineWidth',2.0,'HandleVisibility','off');
shipApp = plot(axApp,nan,nan,'o','MarkerSize',8, ...
    'MarkerFaceColor',[0.89 0.22 0.25],'MarkerEdgeColor',[0.27 0.12 0.15], ...
    'HandleVisibility','off');

axOrb = axes('Parent',fig,'Units','normalized','Position',[0.30 0.14 0.21 0.25]);
drawPhaseBackground(axOrb,m,cfg,2,'CIRCULAR ORBIT',green,b1,b2,b3,b4);
hold(axOrb,'on');
orbTrailPanel = plot(axOrb,nan,nan,'Color',green,'LineWidth',3.8,'HandleVisibility','off');
shipOrb = plot(axOrb,nan,nan,'o','MarkerSize',8, ...
    'MarkerFaceColor',[0.89 0.22 0.25],'MarkerEdgeColor',[0.27 0.12 0.15], ...
    'HandleVisibility','off');

axRet = axes('Parent',fig,'Units','normalized','Position',[0.55 0.14 0.21 0.25]);
drawPhaseBackground(axRet,m,cfg,3,'RETURN',orange,b1,b2,b3,b4);
hold(axRet,'on');
retTrailPanel = plot(axRet,nan,nan,'Color',orange,'LineWidth',2.0,'HandleVisibility','off');
shipRet = plot(axRet,nan,nan,'o','MarkerSize',8, ...
    'MarkerFaceColor',[0.89 0.22 0.25],'MarkerEdgeColor',[0.27 0.12 0.15], ...
    'HandleVisibility','off');

% ----------------------- Time graph and info -----------------------
axClock=axes('Parent',fig,'Units','normalized','Position',[0.79 0.56 0.19 0.23]);
hold(axClock,'on'); grid(axClock,'on');
plot(axClock,m.shipDays,m.stationYearsVec,'Color',[0.11 0.40 0.77], ...
    'LineWidth',2,'DisplayName','Station clock');
plot(axClock,m.shipDays,m.shipDays/365.25,'--', ...
    'Color',[0.55 0.58 0.65],'LineWidth',1.3,'DisplayName','Ship clock');
timeMarker=plot(axClock,0,0,'o','MarkerSize',7, ...
    'MarkerFaceColor',[0.92 0.26 0.20],'MarkerEdgeColor','none', ...
    'HandleVisibility','off');
title(axClock,'TIME DILATION','FontSize',11);
xlabel(axClock,'Ship time (days)'); ylabel(axClock,'Elapsed time (years)');
legend(axClock,'Location','northwest','FontSize',8);

axInfo=axes('Parent',fig,'Units','normalized','Position',[0.79 0.12 0.19 0.31]);
axis(axInfo,'off');
text(axInfo,0.02,0.95,'MISSION PROGRESS', ...
    'FontSize',14,'FontWeight','bold','Units','normalized');
phaseLabel=text(axInfo,0.02,0.82,'APPROACH', ...
    'FontSize',13,'FontWeight','bold','Units','normalized', ...
    'Color',blue);
statsText=text(axInfo,0.02,0.68,'', ...
    'FontSize',10,'Units','normalized','Interpreter','none', ...
    'VerticalAlignment','top');

sgtitle(fig,'GARGANTUA  /  FOUR-BURN PROGRADE CIRCULAR MISSION', ...
    'FontWeight','bold','FontSize',16);

% ----------------------- Animation -----------------------
% Slower approach and return than before.
framesPerPhase = [220 170 220];
phaseNames = {'APPROACH','CIRCULAR ORBIT','RETURN'};
phaseColors = {blue,green,orange};

for phase = 1:3
    ids = find(m.phase==phase);
    if isempty(ids), continue; end
    nFrames = framesPerPhase(phase);

    for j = 1:nFrames
        if ~isgraphics(fig), return; end
        if getappdata(fig,'StopPlayback'), return; end

        f = (j-1)/(nFrames-1);
        iFloat = 1 + f*(numel(ids)-1);
        iLow = max(1,min(numel(ids),floor(iFloat)));
        iHigh = min(numel(ids),iLow+1);
        w = iFloat - iLow;
        idx = ids(iLow); idxNext = ids(iHigh);

        if phase==2
            angle = m.phi(ids(1)) + 2*pi*f;
            rNow  = m.rc;
        else
            angle = (1-w)*m.phi(idx) + w*m.phi(idxNext);
            rNow  = (1-w)*m.r(idx)   + w*m.r(idxNext);
        end
        x = rNow*cos(angle);
        y = rNow*sin(angle);

        % Build trajectories progressively in the 5 graphs.
        if phase==1
            kA = max(1, round(1 + f*(numel(xApp)-1)));
            set(appTrailFull, 'XData',xApp(1:kA),'YData',yApp(1:kA));
            set(appTrailClose,'XData',xApp(1:kA),'YData',yApp(1:kA));
            set(appTrailPanel,'XData',xApp(1:kA),'YData',yApp(1:kA));
        elseif phase==2
            kO = max(1, round(1 + f*(numel(xOrb)-1)));
            set(orbTrailFull, 'XData',xOrb(1:kO),'YData',yOrb(1:kO));
            set(orbTrailClose,'XData',xOrb(1:kO),'YData',yOrb(1:kO));
            set(orbTrailPanel,'XData',xOrb(1:kO),'YData',yOrb(1:kO));
        else
            kR = max(1, round(1 + f*(numel(xRet)-1)));
            set(retTrailFull, 'XData',xRet(1:kR),'YData',yRet(1:kR));
            set(retTrailClose,'XData',xRet(1:kR),'YData',yRet(1:kR));
            set(retTrailPanel,'XData',xRet(1:kR),'YData',yRet(1:kR));
        end

        % Move spacecraft markers.
        set(shipFull,'XData',x,'YData',y);
        set(shipClose,'XData',x,'YData',y);
        set(shipApp,'XData',nan,'YData',nan);
        set(shipOrb,'XData',nan,'YData',nan);
        set(shipRet,'XData',nan,'YData',nan);
        if phase==1
            set(shipApp,'XData',x,'YData',y);
        elseif phase==2
            set(shipOrb,'XData',x,'YData',y);
        else
            set(shipRet,'XData',x,'YData',y);
        end

        % Update clocks and mission text.
        daysNow  = (1-w)*m.shipDays(idx)        + w*m.shipDays(idxNext);
        yearsNow = (1-w)*m.stationYearsVec(idx) + w*m.stationYearsVec(idxNext);
        set(timeMarker,'XData',daysNow,'YData',yearsNow);

        timeGain = yearsNow - daysNow/365.25;
        set(phaseLabel,'String',phaseNames{phase},'Color',phaseColors{phase});
        details = sprintf([ ...
            'Ship elapsed:   %.5g days\n' ...
            'Station clock:  %.8g years\n' ...
            'Net time gained: %.8g years\n\n' ...
            'Circular radius: %.9f r_g\n' ...
            'Circular revolutions: %.5g\n' ...
            'Propellant: %.7g kg\n' ...
            'Fuel cost: $%.7g'], ...
            daysNow,yearsNow,timeGain,m.rc,m.circleRevs,m.fuel.mFuel,m.costUSD);
        set(statsText,'String',details);

        drawnow;
        pause(0.02);
    end
end

if isgraphics(fig)
    set(phaseLabel,'String','MISSION COMPLETE','Color',[0.10 0.53 0.31]);
end

    function stopAndClose(src,~)
        if isgraphics(src)
            setappdata(src,'StopPlayback',true);
            delete(src);
        end
    end
end

% ======================================================================
function drawMissionBackground(ax,m,cfg,mode,b1,b2,b3,b4)
% Draw the static geometry, station, burn markers, and legend.
cla(ax); hold(ax,'on'); grid(ax,'on'); axis(ax,'equal');

theta = linspace(0,2*pi,900);
h = cfg.geom.horizon;
red = [0.79 0.13 0.26];

% Event horizon and ISCO
hPatch = fill(ax,h*cos(theta),h*sin(theta),[0.08 0.12 0.19], ...
    'EdgeColor',[0.08 0.12 0.19],'LineWidth',0.7,'DisplayName','Event horizon');
hPatch.Annotation.LegendInformation.IconDisplayStyle = 'on';
plot(ax,cfg.geom.isco*cos(theta),cfg.geom.isco*sin(theta),'--', ...
    'Color',[0.70 0.55 0.30],'LineWidth',1.1,'DisplayName','Prograde ISCO');

% Space station and burns
plot(ax,cfg.rStation,0,'p','MarkerSize',12, ...
    'MarkerFaceColor',[0.25 0.67 0.40],'MarkerEdgeColor',[0.12 0.29 0.18], ...
    'DisplayName','Space station');
plot(ax,b1(1),b1(2),'s','MarkerSize',7,'MarkerFaceColor',red, ...
    'MarkerEdgeColor',[0.30 0.06 0.09],'DisplayName','B1 Departure');
plot(ax,b2(1),b2(2),'o','MarkerSize',8,'MarkerFaceColor',red, ...
    'MarkerEdgeColor',[0.30 0.06 0.09],'DisplayName','B2 Orbit insertion');
plot(ax,b3(1),b3(2),'d','MarkerSize',8,'MarkerFaceColor',red, ...
    'MarkerEdgeColor',[0.30 0.06 0.09],'DisplayName','B3 Orbit exit');
plot(ax,b4(1),b4(2),'^','MarkerSize',7,'MarkerFaceColor',red, ...
    'MarkerEdgeColor',[0.30 0.06 0.09],'DisplayName','B4 Docking');

% Burn labels
if strcmpi(mode,'full')
    text(ax,b1(1),b1(2)+3,'  B1','FontSize',9,'FontWeight','bold','Color',red);
    text(ax,b4(1),b4(2)-4,'  B4','FontSize',9,'FontWeight','bold','Color',red);
end
text(ax,b2(1),b2(2),'  B2','FontSize',9,'FontWeight','bold','Color',red);
text(ax,b3(1),b3(2),'  B3','FontSize',9,'FontWeight','bold','Color',red);

% Dummy line handles for legend / color meaning.
if strcmpi(mode,'full')
    plot(ax,nan,nan,'Color',[0.12 0.40 0.83],'LineWidth',1.8,'DisplayName','Approach');
    plot(ax,nan,nan,'Color',[0.10 0.61 0.42],'LineWidth',2.8,'DisplayName','Circular orbit');
    plot(ax,nan,nan,'Color',[0.90 0.39 0.17],'LineWidth',1.8,'DisplayName','Return');
end

xlabel(ax,'x / r_g'); ylabel(ax,'y / r_g');
if strcmpi(mode,'full')
    xlim(ax,[-1.08*cfg.rStation 1.08*cfg.rStation]);
    ylim(ax,[-1.08*cfg.rStation 1.08*cfg.rStation]);
    legend(ax,'Location','southoutside','NumColumns',4,'FontSize',8);
else
    lim = 1.35*max(m.rc,cfg.geom.isco);
    xlim(ax,[-lim lim]);
    ylim(ax,[-lim lim]);
end
end

function drawPhaseBackground(ax,m,cfg,phaseNum,phaseTitle,lineColor,b1,b2,b3,b4)
% Draw static references for one phase panel.
cla(ax); hold(ax,'on'); grid(ax,'on'); axis(ax,'equal');

theta = linspace(0,2*pi,700);
h = cfg.geom.horizon;
red = [0.79 0.13 0.26];

fill(ax,h*cos(theta),h*sin(theta),[0.08 0.12 0.19], ...
    'EdgeColor',[0.08 0.12 0.19],'LineWidth',0.7);
plot(ax,cfg.geom.isco*cos(theta),cfg.geom.isco*sin(theta),'--', ...
    'Color',[0.70 0.55 0.30],'LineWidth',1.0);

% Plot relevant burns for each panel.
if phaseNum==1
    plot(ax,b1(1),b1(2),'s','MarkerSize',7,'MarkerFaceColor',red, ...
        'MarkerEdgeColor',[0.30 0.06 0.09]);
    plot(ax,b2(1),b2(2),'o','MarkerSize',8,'MarkerFaceColor',red, ...
        'MarkerEdgeColor',[0.30 0.06 0.09]);
elseif phaseNum==2
    plot(ax,b2(1),b2(2),'o','MarkerSize',8,'MarkerFaceColor',red, ...
        'MarkerEdgeColor',[0.30 0.06 0.09]);
    plot(ax,b3(1),b3(2),'d','MarkerSize',8,'MarkerFaceColor',red, ...
        'MarkerEdgeColor',[0.30 0.06 0.09]);
else
    plot(ax,b3(1),b3(2),'d','MarkerSize',8,'MarkerFaceColor',red, ...
        'MarkerEdgeColor',[0.30 0.06 0.09]);
    plot(ax,b4(1),b4(2),'^','MarkerSize',7,'MarkerFaceColor',red, ...
        'MarkerEdgeColor',[0.30 0.06 0.09]);
end

% Faint reference path under the animated trajectory.
ids = find(m.phase==phaseNum);
if phaseNum==2
    thetaRef = linspace(0,2*pi,900);
    plot(ax,m.rc*cos(thetaRef),m.rc*sin(thetaRef), ...
        'Color',lineColor,'LineStyle','--','LineWidth',1.0);
else
    [x,y] = polarPlotSamples(m.r(ids),m.phi(ids));
    plot(ax,x,y,'Color',lineColor,'LineStyle','--','LineWidth',0.9);
end

xlabel(ax,'x / r_g'); ylabel(ax,'y / r_g');
title(ax,phaseTitle,'FontSize',10,'FontWeight','bold');

if phaseNum==1 || phaseNum==3
    rMax = max(m.r(ids));
    lim = 1.08*rMax;
else
    lim = 1.35*max(m.rc,cfg.geom.isco);
end
xlim(ax,[-lim lim]); ylim(ax,[-lim lim]);
end

function [x,y] = polarPlotSamples(r,phi)
% Smooth plotting path using interpolation in polar coordinates.
r = r(:); phi = phi(:);
x = []; y = [];
for i = 1:numel(r)-1
    deltaPhi = abs(phi(i+1)-phi(i));
    steps = max(1,ceil(deltaPhi/0.025));
    if steps > 50000
        x=[x;NaN]; %#ok<AGROW>
        y=[y;NaN]; %#ok<AGROW>
        continue;
    end
    f = (0:steps-1)'/steps;
    rr = r(i) + (r(i+1)-r(i))*f;
    pp = phi(i) + (phi(i+1)-phi(i))*f;
    x = [x; rr.*cos(pp)]; %#ok<AGROW>
    y = [y; rr.*sin(pp)]; %#ok<AGROW>
end
x = [x; r(end)*cos(phi(end))];
y = [y; r(end)*sin(phi(end))];
end
