function hr = LLHR(correct, validProbe)
    %hits = sum(correct(find(validProbe == 1))) + 0.5;
    %hits = sum((correct == validProbe) & (correct == 1)) + 0.5;
    hits = sum(correct(find(validProbe))) + 0.5;
    hr = hits/(sum(validProbe) + 1);
end