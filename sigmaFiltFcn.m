function v = sigmaFiltFcn(A, stdval)
% Apply the Sigma Filter from Jong-Sen Lee
%
% Author: H Muammar
% Date: 12 May 2010

mn = size(A, 1);

%stdval = std(A, 0, 1);
%stdval = 1.5;

delta = 2.0.*stdval;

x = A((floor(mn./2) + 1), :);
rngU = x + delta;
rngL = x - delta;

U = repmat(rngU, [mn 1]);
L = repmat(rngL, [mn 1]);

index = (A >= L) & (A <= U);

sumi = sum(index, 1);
sumbuf = sum(A.*index, 1);

zro = sumi == 0;
v = repmat(0, size(sumi));
v(~zro) = sumbuf(~zro)./sumi(~zro);
v(zro) = sumbuf(zro);

return