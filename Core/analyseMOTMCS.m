function [speed q] = analyseMOTMCS(subject_name, attempt_num)
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file') && ~exist('mot_mcs_data', 'var')
        load(data_fn);
    end
    
    s = [];
    c = [];
    for i = attempt_num
        s = [s mot_mcs_data{i}.speed];
        c = [c mot_mcs_data{i}.correct];
    end
    graphMOTMCS(s, c, attempt_num);
    fprintf('Estimating threshold...\n');
    [speed q] = CalcThreshold(s, c, 0.75, .5);
    fprintf('Suggested speed: %f\n', speed);
end

function graphMOTMCS(s, c, attempt_num)
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
    xlabel('Speed');
    ylabel('Percent Correct');
    title(sprintf('MOT MCS Attempt %s', num2str(attempt_num)));
    drawnow;
end

