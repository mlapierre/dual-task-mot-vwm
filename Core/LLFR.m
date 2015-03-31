function fr = LLFR(correct, validProbe)
    %frs = sum((correct ~= validProbe) & (correct == 0)) + 0.5;
    %frs = sum(correct(find(nonTargets == 1))) + 0.5;
    frs = sum(~correct(find(~validProbe))) + 0.5;
    fr = frs/(sum(~validProbe) + 1);
end