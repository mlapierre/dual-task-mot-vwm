function graphMOTMCS(subject_name, attempt_num)
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file') && ~exist('mot_mcs_data', 'var')
        load(data_fn);
        fprintf('Data and loaded from %s\n', data_fn);
    end
    
    s = mot_mcs_data{attempt_num}.speed;
    c = mot_mcs_data{attempt_num}.correct;
    
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
    title(sprintf('MOT MCS Attempt %d', attempt_num));
    drawnow;
end

