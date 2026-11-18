function geometry = kerrGeometry(a)
% KERRGEOMETRY  Event horizon and prograde ISCO of a Kerr black hole.
%
% Input:  a = dimensionless black-hole spin, 0 <= a < 1
% Output: geometry.horizon, geometry.isco (radii in GM/c^2)
%
% These are analytical formulas; no numerical integration is needed.
if a < 0 || a >= 1
    error('Spin must satisfy 0 <= a < 1.');
end

z1 = 1 + (1-a^2)^(1/3)*((1+a)^(1/3)+(1-a)^(1/3));
z2 = sqrt(3*a^2+z1^2);

geometry.horizon = 1 + sqrt(1-a^2);
geometry.isco = 3 + z2 - sqrt((3-z1)*(3+z1+2*z2));
end
