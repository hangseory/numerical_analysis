function report = kerrValidate(cfg)
% KERRVALIDATE  Simple numerical checks, following class convergence examples.
% Compare analytic Schwarzschild results and halving RK4 step size.

blackHole=kerrGeometry(0);
orbit=kerrCircular(10,0);
report.schwarzschildHorizonError=abs(blackHole.horizon-2);
report.schwarzschildISCOError=abs(blackHole.isco-6);
report.circularDerror=abs(orbit.D-1/sqrt(1-3/10));

% Integrate the same transfer with h, h/2 and h/4.
rc=cfg.geom.isco+max(0.5,cfg.iscoMargin+0.1);
steps=[100 200 400];
report.phi=zeros(1,3);
report.transferAvailable=true;
for i=1:3
    tr=kerrTransfer(rc,1,cfg,steps(i));
    if ~tr.ok
        report.transferAvailable=false;
        break;
    end
    report.phi(i)=tr.phiHalf;
end
if report.transferAvailable
    e1=abs(report.phi(1)-report.phi(2));
    e2=abs(report.phi(2)-report.phi(3));
    report.stepRatio=e1/max(e2,eps);
else
    report.stepRatio=NaN;
end

fprintf('\nVALIDATION\n');
fprintf('Schwarzschild horizon error: %.3e\n',report.schwarzschildHorizonError);
fprintf('Schwarzschild ISCO error:    %.3e\n',report.schwarzschildISCOError);
fprintf('Circular time factor error: %.3e\n',report.circularDerror);
fprintf('RK4 step-halving error ratio: %.4f (ideal approximately 16)\n',report.stepRatio);
end
