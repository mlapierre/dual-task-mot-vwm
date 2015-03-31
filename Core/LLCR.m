function cr = LLCR(correct, validProbe)
    nonTargets = validProbe == 0;
    crs = sum(correct == nonTargets);
    cr = crs/sum(nonTargets);
end