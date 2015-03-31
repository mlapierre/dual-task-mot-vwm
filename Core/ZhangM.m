% Calculate mean number of objects tracked (as per Zhang et al. 2010)
function m = ZhangM(n, hr, cr)
    m = n*((hr + cr - 1)/cr);
    if m < 0
        m = 0;
    end
end
