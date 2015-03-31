function x = probit(p)

% probit(p) = sqrt(2)*erfinv(2p-1)

x = sqrt(2) * erfinv((2 * p) - 1);