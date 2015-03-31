% Calculate mean number of conjunctions remembered (as per Zhang et al. 2010)
function k = ZhangK(n, hr, cr)
    k = (n*hr+n-1-sqrt((n*hr+n-1)^2 - 4*n*(n-1)*(hr+cr-1)))/2;
end