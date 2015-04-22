function StartMOTMCS(subject_name)
    KbName('UnifyKeyNames');
    if nargin < 1
        subject_name = '';
    end
    [valid, subject_name] = isValidSubjectName(subject_name);
    if ~valid
        return
    end
    fprintf('Participant: %s\n', subject_name);
    
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file')
        load(data_fn);
        fprintf('Data and config loaded from %s\n', data_fn);
    else
        fprintf('%s has not participated in this experiment before\n', subject_name);
        fprintf('Saving data and config to: %s\n', data_fn);
    end
    
    if exist('config', 'var')
        fprintf('MOT calibration has been completed\n');
        return
    end
    
    ListenChar(2);
    fprintf('\nMOT calibration has not been completed\n');
    fprintf('Please press a key to begin the first stage...\n');
    GetKbChar();
    speed = MOT_MCS(subject_name, 50, 10, 2);
    
    fprintf('Please press ''y'' to begin the second stage, or any other key to quit...\n');
    char = GetKbChar();
    if char ~= 'y'
        ListenChar(0);
        return
    end
    MOT_MCS(subject_name, 50, speed, 1);

    fprintf('Estimating final threshold based on last 2 attempts...\n');
    if ~exist('mot_mcs_data', 'var')
        load(data_fn);
    end
    nAttempts = size(mot_mcs_data, 2);

    s = [mot_mcs_data{nAttempts-1}.speed mot_mcs_data{nAttempts}.speed];
    c = [mot_mcs_data{nAttempts-1}.correct mot_mcs_data{nAttempts}.correct];

    [speed mot_mcs_data{nAttempts}.qFinal] = CalcThreshold(s, c, 0.7, .5);
    fprintf('Suggested speed: %f\n', speed);                                         

    % Display graph of combined results
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
    title('MOT percent correct by speed');
    
    save(data_fn, 'mot_mcs_data', 'mot_mcs_config');
    ListenChar(0);
end