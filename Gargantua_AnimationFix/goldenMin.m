function [xBest,fBest] = goldenMin(fun,a,b,maxIter,tol)
% GOLDENMIN  Find a local minimum of a function on [a,b].
% Based on the GoldSearch.m algorithm supplied in the course.
%
% Unlike the class example (which finds a MAXIMUM), this finds a MINIMUM.
% Assumes a single minimum inside the chosen bracket.
R = (sqrt(5)-1)/2;
x1 = b-R*(b-a);
x2 = a+R*(b-a);
f1 = fun(x1);
f2 = fun(x2);

for iter = 1:maxIter
    if abs(b-a) < tol, break; end
    if f1 <= f2
        b = x2;
        x2 = x1; f2 = f1;
        x1 = b-R*(b-a);
        f1 = fun(x1);
    else
        a = x1;
        x1 = x2; f1 = f2;
        x2 = a+R*(b-a);
        f2 = fun(x2);
    end
end
if f1 < f2
    xBest=x1; fBest=f1;
else
    xBest=x2; fBest=f2;
end
end
