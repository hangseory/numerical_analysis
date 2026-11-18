function main
% MAIN  Gargantua time-machine project | MEU3003 Numerical Analysis
%
% Run this file by typing:   main
%
% USER INPUTS: desired time gained (years), maximum ship time (days).
% MODEL: prograde circular orbit only, four burns, station-to-station.
% ENGINEERING METHODS: RK4, finite search and Golden-section minimization.
%
% All astronomy/engine values are fixed below. Change them only if your
% team decides to use different assumptions. They are NOT film-verified
% spacecraft/engine specifications.

clc;
cfg = missionSettings();

%% ---- User interface ---------------------------------------------------
navy=[0.08 0.13 0.22]; blue=[0.12 0.40 0.80];
background=[0.965 0.976 0.988];
% Build the window at the original layout size.  After the controls are
% created, fit it to the usable screen so the OS title bar and X remain
% reachable even on a laptop screen.
app=uifigure('Name','GARGANTUA | Mission Designer', ...
    'Position',[60 50 1400 850],'Color',background);

% Header
header=uipanel(app,'Position',[0 772 1400 78], ...
    'BackgroundColor',navy,'BorderType','none');
uilabel(header,'Text','GARGANTUA', ...
    'Position',[30 37 500 33],'FontSize',25,'FontWeight','bold', ...
    'FontColor',[1 1 1]);
uilabel(header,'Text','KERR BLACK HOLE  /  MINIMUM-FUEL MISSION DESIGN', ...
    'Position',[32 14 670 20],'FontSize',11, ...
    'FontColor',[0.73 0.83 0.96]);

% Left: settings panel
left=uipanel(app,'Title','MISSION REQUIREMENTS', ...
    'Position',[22 115 322 634], 'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',[1 1 1]);
uilabel(left,'Text','Desired future time gain', ...
    'Position',[20 559 280 22],'FontWeight','bold');
inputGain=uieditfield(left,'numeric','Value',100, ...
    'Limits',[0 Inf],'Position',[20 517 280 39], ...
    'ValueDisplayFormat','%.6g years','FontSize',15);

uilabel(left,'Text','Maximum spacecraft time', ...
    'Position',[20 467 280 22],'FontWeight','bold');
inputDays=uieditfield(left,'numeric','Value',30.4375, ...
    'Limits',[1e-9 Inf],'Position',[20 425 280 39], ...
    'ValueDisplayFormat','%.6g days','FontSize',15);

uilabel(left,'Text','FIXED MISSION ASSUMPTIONS', ...
    'Position',[20 378 280 22],'FontWeight','bold', ...
    'FontColor',blue);
fixedText={ ...
    'Black hole: 100 million solar masses'; ...
    'Spin: 1 - 10^{-14} (near extremal)'; ...
    'Craft dry mass: 100,000 kg (assumed)'; ...
    'Exhaust speed: 0.15c (assumed)'; ...
    'Station radius: 40 gravitational radii'; ...
    'Orbit: prograde, minimum one revolution'; ...
    'Burns: departure / insertion / exit / docking'};
uitextarea(left,'Position',[20 109 280 260], ...
    'Value',fixedText,'Editable','off','FontSize',11, ...
    'BackgroundColor',[0.96 0.975 0.99]);

runBtn=uibutton(left,'push','Text','RUN OPTIMIZATION', ...
    'Position',[20 30 280 47], 'FontSize',13,'FontWeight','bold', ...
    'BackgroundColor',blue,'FontColor',[1 1 1], ...
    'ButtonPushedFcn',@runOptimization);

% Right top: numerical summary
summary=uipanel(app,'Title','MISSION RESULTS', ...
    'Position',[365 115 1013 227], 'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',[1 1 1]);
resultText=uitextarea(summary,'Position',[17 42 979 158], ...
    'Editable','off','FontName','Consolas','FontSize',12, ...
    'BackgroundColor',[0.975 0.983 0.992], ...
    'Value',{'Enter your mission requirements, then select RUN OPTIMIZATION.'; ...
             'Only prograde circular-orbit missions are evaluated.'});
statusLabel=uilabel(summary,'Text','Status: Ready', ...
    'Position',[17 10 979 25], 'FontSize',12, ...
    'FontColor',[0.19 0.40 0.64]);

% Right top: Two large plots at different spatial scales.
% The full plot shows the station and transfer paths. The zoomed plot
% makes the tiny near-horizon circular orbit visible separately.
trajectoryPanel=uipanel(app,'Title','SPACECRAFT TRAJECTORY  |  FULL MISSION + BLACK HOLE CLOSE-UP', ...
    'Position',[365 355 1013 394], 'FontSize',12, ...
    'FontWeight','bold','BackgroundColor',[1 1 1]);

ax=uiaxes(trajectoryPanel,'Position',[18 48 594 313]);
axis(ax,'equal');grid(ax,'on');
title(ax,'Full trajectory: station to black hole and back');

axZoom=uiaxes(trajectoryPanel,'Position',[645 48 344 313]);
axis(axZoom,'equal');grid(axZoom,'on');
title(axZoom,'Close-up near Gargantua');

% Bottom action bar
footer=uipanel(app,'Position',[22 15 1356 88], ...
    'BackgroundColor',[1 1 1], 'BorderType','line');
playBtn=uibutton(footer,'push','Text','PLAY MISSION ANIMATION', ...
    'Position',[20 35 245 38], 'Enable','off', ...
    'FontWeight','bold','ButtonPushedFcn',@playMission);
exportBtn=uibutton(footer,'push','Text','SAVE RESULT FIGURE + CSV', ...
    'Position',[278 35 245 38], 'Enable','off', ...
    'FontWeight','bold','ButtonPushedFcn',@saveResults);
uilabel(footer,'Text', ...
    ['Research model: symmetric transfer geodesics, four ideal burns, ' ...
     'station return. Lowest feasible candidate found; not a proven global optimum.'], ...
    'Position',[545 37 565 25],'FontSize',11, ...
    'FontColor',[0.34 0.39 0.47]);
uilabel(footer,'Text', ...
    'Assumed propellant price excludes engine, infrastructure, launch and operation costs.', ...
    'Position',[545 12 565 20], 'FontSize',10, ...
    'FontColor',[0.47 0.51 0.56]);

% Keep a permanent close button even if the window decorations are hidden.
closeBtn=uibutton(footer,'push','Text','CLOSE WINDOW', ...
    'Position',[1120 35 210 38], 'FontWeight','bold', ...
    'ButtonPushedFcn',@(~,~) delete(app));

% Resize every control proportionally; do it BEFORE displaying results.
fitDashboardToScreen(app,1400,850);

best=[];

    function runOptimization(~,~)
        % The callback is invoked when the button is clicked.
        cfg.targetYears=inputGain.Value;
        cfg.maxShipYears=inputDays.Value/365.25;
        if ~isfinite(cfg.targetYears) || cfg.targetYears<0 || ...
                ~isfinite(cfg.maxShipYears) || cfg.maxShipYears<=0
            uialert(app,'Enter valid nonnegative years and positive days.', ...
                'Invalid input');
            return;
        end
        runBtn.Enable='off'; playBtn.Enable='off'; exportBtn.Enable='off';
        statusLabel.Text='Status: Solving Kerr trajectories...';
        resultText.Value={'Searching for feasible missions...'; ...
           'This can take time for near-extremal Kerr spin.'};
        drawnow;
        try
            [candidate,info]=kerrOptimize(cfg);
            if ~isvalid(app), return; end
            best=candidate;
            if candidate.ok
                resultText.Value=reportLines(candidate,cfg,info);
                statusLabel.Text='Status: Feasible candidate found';
                plotTrajectory(ax,candidate,cfg,'full');
                plotTrajectory(axZoom,candidate,cfg,'zoom');
                title(ax,'Full mission: approach / orbit / return');
                title(axZoom,'Magnified circular orbit and horizon');
                playBtn.Enable='on'; exportBtn.Enable='on';
            else
                resultText.Value={ ...
                  'NO FEASIBLE CANDIDATE FOUND'; ...
                  candidate.reason; ...
                  sprintf('Candidates evaluated: %d',info.evaluated); ...
                  'This does NOT prove that the requested mission is impossible.'; ...
                  'Try a smaller time target or larger spacecraft-time limit.'};
                statusLabel.Text='Status: No feasible candidate in search domain';
                cla(ax);cla(axZoom);
                title(ax,'No feasible trajectory in current search.');
                title(axZoom,'No feasible circular orbit.');
            end
        catch ME
            if ~isvalid(app), return; end
            best=[];
            statusLabel.Text='Status: Numerical error';
            resultText.Value={['Numerical error: ' ME.message]};
            uialert(app,ME.message,'Numerical solver error');
        end
        if isvalid(app),runBtn.Enable='on';end
    end

    function playMission(~,~)
        if isempty(best) || ~best.ok,return;end
        kerrPresentation(best,cfg);
    end

    function saveResults(~,~)
        if isempty(best) || ~best.ok,return;end
        if ~exist(cfg.outputDir,'dir'),mkdir(cfg.outputDir);end
        % CSV and PNG are exported to the local results folder.
        fid=fopen(fullfile(cfg.outputDir,'mission_results.csv'),'w');
        fprintf(fid,'Parameter,Value\n');
        fprintf(fid,'Target gain (years),%.12g\n',cfg.targetYears);
        fprintf(fid,'Maximum ship time (years),%.12g\n',cfg.maxShipYears);
        fprintf(fid,'Orbit radius (rg),%.12g\n',best.rc);
        fprintf(fid,'Circular revolutions,%.12g\n',best.circleRevs);
        fprintf(fid,'Ship time (years),%.12g\n',best.shipYears);
        fprintf(fid,'Station time (years),%.12g\n',best.stationYears);
        fprintf(fid,'Net time gained (years),%.12g\n',best.gainYears);
        fprintf(fid,'Fuel mass (kg),%.12g\n',best.fuel.mFuel);
        fprintf(fid,'Estimated propellant cost (USD),%.12g\n',best.costUSD);
        fclose(fid);
        fig=figure('Visible','off','Color','w','Position',[100 100 900 700]);
        axSave=axes(fig);
        plotTrajectory(axSave,best,cfg,'full');
        title(axSave,'Gargantua: Best Feasible Circular Orbit');
        exportgraphics(fig,fullfile(cfg.outputDir,'mission_trajectory.png'), ...
            'Resolution',180);
        close(fig);
        statusLabel.Text=['Status: Saved figures to ' cfg.outputDir];
    end
end

function fitDashboardToScreen(app,referenceW,referenceH)
% FITDASHBOARDTOSCREEN  Scale the original pixel layout to fit the display.
% The height margin leaves room for MATLAB's / Windows' title bars.
% This avoids a window whose X button is off the top of the screen.
rect=get(groot,'ScreenSize');
usableW=max(620,rect(3)-110);
usableH=max(480,rect(4)-155);
scale=min([1,usableW/referenceW,usableH/referenceH]);
newW=round(referenceW*scale);
newH=round(referenceH*scale);

% Recursively scale panels, plots, labels, edit fields and buttons.
scaleChildren(app,scale);
left=rect(1)+max(5,floor((rect(3)-newW)/2));
bottom=rect(2)+max(48,floor((rect(4)-newH)/2));
app.Position=[left bottom newW newH];
end

function scaleChildren(parent,scale)
% UI children are positioned relative to their immediate parent.
children=parent.Children;
for i=1:numel(children)
    child=children(i);
    if isprop(child,'Position')
        pos=child.Position;
        if numel(pos)==4
            child.Position=max(1,round(pos*scale));
        end
    end
    % MATLAB automatically clips axes labels at small sizes. Reduce all
    % fonts moderately, without making them unreadably tiny.
    if isprop(child,'FontSize') && scale<0.98
        child.FontSize=max(9,round(child.FontSize*max(scale,0.78)));
    end
    if isprop(child,'Children') && ~isempty(child.Children)
        scaleChildren(child,scale);
    end
end
end

function cfg = missionSettings()
% CONSTANTS AND SIMULATION OPTIONS shared by all function files.
% The astronomical values are Interstellar-inspired; spacecraft, station,
% fuel price and engine specifications are educational assumptions.
cfg.Msolar=1e8;
cfg.a=1-1e-14;
cfg.mDry=100000;
cfg.c=299792458;
cfg.ve=0.15*cfg.c;
cfg.rStation=40;
cfg.fuelPriceUSDperKg=100;

% Physical units and natural-unit conversion factors.
cfg.G=6.67430e-11;
cfg.Msun=1.98847e30;
cfg.yearSeconds=365.25*86400;
cfg.tUnit=cfg.G*(cfg.Msolar*cfg.Msun)/cfg.c^3;
cfg.rUnit=cfg.G*(cfg.Msolar*cfg.Msun)/cfg.c^2;
cfg.geom=kerrGeometry(cfg.a);

% Search/accuracy settings (adjust only after testing convergence).
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
end

function lines=reportLines(m,cfg,info)
% Strings shown in the results panel.
lines={ ...
    'SUCCESS  |  BEST FEASIBLE CANDIDATE IN SEARCH DOMAIN'; ...
    sprintf('Black hole          M = %.3g solar masses  |  a = 1 - 1e-14',cfg.Msolar); ...
    sprintf('Circular radius     %.9f r_g',m.rc); ...
    sprintf('Circular revolutions  %.3f',m.circleRevs); ...
    sprintf('Spacecraft time     %.6g days',m.shipYears*365.25); ...
    sprintf('Station elapsed     %.9g years',m.stationYears); ...
    sprintf('NET TIME GAIN       %.9g years',m.gainYears); ...
    sprintf('Propellant mass     %.8g kg',m.fuel.mFuel); ...
    sprintf('ESTIMATED FUEL COST $%.8g USD  (assumed $%.2f/kg)', ...
       m.costUSD,cfg.fuelPriceUSDperKg); ...
    sprintf('Burns                4   |   Candidates tested: %d',info.evaluated); ...
    'Return/docking      Angular closure + fourth matching burn'; ...
    'Scope                Restricted symmetric-transfer model'};
end
