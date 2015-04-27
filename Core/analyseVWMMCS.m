function [disc_count q] = analyseVWMMCS(subject_name, attempt_num)
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file') && ~exist('vwm_mcs_data', 'var')
        load(data_fn);
        fprintf('Data and loaded from %s\n', data_fn);
    end
    
    s = [];
    c = [];
    for i = attempt_num
        s = [s vwm_mcs_data{i}.num_discs];
        c = [c vwm_mcs_data{i}.correct];
    end
    graphVWMMCS(s, c, attempt_num);
    fprintf('Estimating threshold...\n');
    [disc_count q] = CalcThreshold(s, c, 0.75, .5);
    fprintf('Suggested disc count: %d\n', round(disc_count));
end

function graphVWMMCS(s, c, attempt_num)
    intensities = unique(s);
    nCorrect = zeros(1,length(intensities));
    nTrials = zeros(1,length(intensities));

    for i=1:length(intensities)
        id = s == intensities(i) & isreal(c);
        nTrials(i) = sum(id);
        nCorrect(i) = sum(c(id));
    end
    pCorrect = nCorrect./nTrials;
    
    figure;
    x = sort(unique(s));
    y = pCorrect;
    bar(x,y);
    xlabel('Disc count');
    ylabel('Percent Correct');
    title(sprintf('VWM MCS Attempt %s', num2str(attempt_num)));
    drawnow;
end

