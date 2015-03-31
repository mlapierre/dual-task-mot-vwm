function cr = getCR(correct, validProbe)
    %crs = sum((correct ~= validProbe) & (correct == 1));
    crs = sum(correct(find(~validProbe)));
    cr = crs/(sum(~validProbe)+1);
end