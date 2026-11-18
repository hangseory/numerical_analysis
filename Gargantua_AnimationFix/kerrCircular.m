function orbit = kerrCircular(r,a)
% KERRCIRCULAR  Prograde circular geodesic in the equatorial Kerr plane.
%
% r: orbital radius in GM/c^2; a: dimensionless spin
% E and L: conserved specific orbital energy and angular momentum
% D = dt/dtau: time-dilation factor relative to the distant coordinate time
% Omega = dphi/dt: orbital angular velocity
%
% A *stable* orbit additionally needs r > ISCO; checked by kerrMission.
q = r^(3/2) - 3*sqrt(r) + 2*a;
if q <= 0
    error('No timelike circular geodesic at this radius.');
end
orbit.Omega = 1/(r^(3/2)+a);
orbit.D = (r^(3/2)+a)/sqrt(r^3-3*r^2+2*a*r^(3/2));
orbit.ut = orbit.D;
orbit.uphi = orbit.Omega*orbit.D;
orbit.E = (r^(3/2)-2*sqrt(r)+a)/(r^(3/4)*sqrt(q));
orbit.L = (r^2-2*a*sqrt(r)+a^2)/(r^(3/4)*sqrt(q));
end
