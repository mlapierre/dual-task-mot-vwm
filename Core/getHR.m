function hr = getHR(correct, validProbe)
    %hits = sum((correct == validProbe) & (correct == 1));
    %hits = sum(correct(find(validProbe == 1)));
    hits = sum(correct(find(validProbe)));
    hr = hits/sum(validProbe);
end