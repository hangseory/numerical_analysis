function plotTrajectory(ax,m,cfg,viewMode)
% PLOTTRAJECTORY  Draw the calculated Kerr trajectories clearly.
%
% viewMode = 'full': entire approach and return (all computed winding).
% viewMode = 'zoom': zoomed view near the black hole.
%
% The plotted curves come from the calculated trajectory. For display only,
% additional polar-coordinate interpolation points are inserted so that the
% graph does not falsely draw straight chords through the black hole.

if nargin < 4
    viewMode = 'full';
end
isZoom = strcmpi(viewMode,'zoom');
cla(ax);
hold(ax,'on');

blue   = [0.12 0.40 0.83];
green  = [0.10 0.61 0.42];
orange = [0.90 0.39 0.17];
red    = [0.79 0.13 0.26];

% ---- 1. Trajectory curves ----
idsApp = find(m.phase==1);
idsRet = find(m.phase==3);
[xA,yA] = polarPlotSamples(m.r(idsApp),m.phi(idsApp));
[xR,yR] = polarPlotSamples(m.r(idsRet),m.phi(idsRet));

plot(ax,xA,yA,'Color',blue,'LineWidth',1.8,'DisplayName','Approach');
plot(ax,m.rc*cos(linspace(0,2*pi,1200)),m.rc*sin(linspace(0,2*pi,1200)), ...
    'Color',green,'LineWidth',2.8,'DisplayName','Circular orbit');
plot(ax,xR,yR,'Color',orange,'LineWidth',1.8,'DisplayName','Return');

% ---- 2. Event horizon and ISCO ----
theta = linspace(0,2*pi,1000);
h = cfg.geom.horizon;
if min(m.r) <= h
    warning('Calculated trajectory reaches or crosses the event horizon.');
end
fill(ax,h*cos(theta),h*sin(theta),[0.08 0.12 0.19], ...
    'EdgeColor',[0.08 0.12 0.19], 'LineWidth',0.7, ...
    'DisplayName','Event horizon');
plot(ax,cfg.geom.isco*cos(theta),cfg.geom.isco*sin(theta),'--', ...
    'Color',[0.70 0.55 0.30], 'LineWidth',1.1, ...
    'DisplayName','Prograde ISCO');

% ---- 3. Station and burn locations ----
idxIn = find(m.phase==1,1,'last');
idxCircle = find(m.phase==2,1,'last');
if ~isempty(idxIn) && ~isempty(idxCircle)
    b1 = [cfg.rStation,0];
    b2 = [m.x(idxIn),m.y(idxIn)];
    b3 = [m.x(idxCircle),m.y(idxCircle)];
    b4 = [cfg.rStation,0];

    % Actual station marker
    plot(ax,cfg.rStation,0,'p','MarkerSize',12, ...
        'MarkerFaceColor',[0.25 0.67 0.40], ...
        'MarkerEdgeColor',[0.12 0.29 0.18], ...
        'DisplayName','Space station');

    % Burn markers (B1/B4 occur at the station)
    plot(ax,b1(1),b1(2),'s','MarkerSize',7, ...
        'MarkerFaceColor',red,'MarkerEdgeColor',[0.30 0.06 0.09], ...
        'DisplayName','B1 Departure');
    plot(ax,b2(1),b2(2),'o','MarkerSize',8, ...
        'MarkerFaceColor',red,'MarkerEdgeColor',[0.30 0.06 0.09], ...
        'DisplayName','B2 Orbit insertion');
    plot(ax,b3(1),b3(2),'d','MarkerSize',8, ...
        'MarkerFaceColor',red,'MarkerEdgeColor',[0.30 0.06 0.09], ...
        'DisplayName','B3 Orbit exit');
    plot(ax,b4(1),b4(2),'^','MarkerSize',7, ...
        'MarkerFaceColor',red,'MarkerEdgeColor',[0.30 0.06 0.09], ...
        'DisplayName','B4 Docking');

    % Burn labels
    if ~isZoom
        text(ax,b1(1),b1(2)+3,'  B1', ...
            'FontSize',9,'FontWeight','bold','Color',red);
        text(ax,b4(1),b4(2)-4,'  B4', ...
            'FontSize',9,'FontWeight','bold','Color',red);
    end
    text(ax,b2(1),b2(2),'  B2', ...
        'FontSize',9,'FontWeight','bold','Color',red);
    text(ax,b3(1),b3(2),'  B3', ...
        'FontSize',9,'FontWeight','bold','Color',red);
end

axis(ax,'equal'); grid(ax,'on');
xlabel(ax,'x / r_g'); ylabel(ax,'y / r_g');

if isZoom
    lim = 1.35*max(m.rc,cfg.geom.isco);
    xlim(ax,[-lim lim]);
    ylim(ax,[-lim lim]);
    legend(ax,'off');
    title(ax,'Zoomed view near the black hole');
else
    xlim(ax,[-1.08*cfg.rStation 1.08*cfg.rStation]);
    ylim(ax,[-1.08*cfg.rStation 1.08*cfg.rStation]);
    legend(ax,'Location','southoutside','NumColumns',4,'FontSize',8);
end
hold(ax,'off');
end

function [x,y] = polarPlotSamples(r,phi)
% POLARPLOTSAMPLES  Insert plotting points between calculated (r,phi)
% samples for a smooth display.

r=r(:); phi=phi(:);
x=[]; y=[];
for i=1:numel(r)-1
    deltaPhi = abs(phi(i+1)-phi(i));
    steps = max(1,ceil(deltaPhi/0.025));
    if steps>50000
        x=[x; NaN]; %#ok<AGROW>
        y=[y; NaN]; %#ok<AGROW>
        continue;
    end
    f=(0:steps-1)'/steps;
    rr=r(i)+(r(i+1)-r(i))*f;
    pp=phi(i)+(phi(i+1)-phi(i))*f;
    x=[x;rr.*cos(pp)]; %#ok<AGROW>
    y=[y;rr.*sin(pp)]; %#ok<AGROW>
end
x=[x;r(end)*cos(phi(end))];
y=[y;r(end)*sin(phi(end))];
end
