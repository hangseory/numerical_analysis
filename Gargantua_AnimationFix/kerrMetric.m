function g = kerrMetric(r,a)
% KERRMETRIC  Metric components at the equator of a Kerr black hole.
% Coordinate order: [t, r, phi]. Natural units G=c=M=1.
%
% Used to compare the spacecraft's four-velocity before and after a burn.
horizon = 1 + sqrt(1-a^2);
inner = 1 - sqrt(1-a^2);
delta = (r-horizon)*(r-inner); % More stable than r^2-2*r+a^2

g = [-(1-2/r), 0, -2*a/r; ...
       0, r^2/delta, 0; ...
      -2*a/r, 0, r^2+a^2+2*a^2/r];
end
