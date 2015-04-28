function est_discs = VWM_MCS(subject_name, num_trials, disc_range, speed)
%   VWM calibration
%   subject_name: The name of the participant.
%   num_trials:   The number of trials on which the participant will be tested.
%   disc_range:   The range of number of discs that will be displayed.

    st = dbstack(1);
    if strcmp(st(1).name, 'StartMOTMCS') ~= true
        if nargin < 1
            subject_name = '';
        end
        [valid, subject_name] = isValidSubjectName(subject_name);
        if ~valid
            return
        end
        if mod(num_trials, size(disc_range, 2)) ~= 0
           error('disc_range must be able to evenly span num_trials'); 
        end
        fprintf('Participant: %s\n', subject_name);
    end
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file') && ~exist('vwm_mcs_data', 'var')
        load(data_fn);
    end
    
    % Set sim = 1 to simulate trials with approximate performance for each disc
    % count as specified below.
    sim = 0;
    if sim == 1
        if size(disc_range, 2) == 5 % test
            p = [0.99 0.85 0.75 0.25 0.05]; % test
        else % test
            p = [0.85 0.65 0.25]; % test
        end % test
        data.correct = gen_binornd_correct(p, num_trials); % test
        data.num_discs = sort(repmat(disc_range, 1, num_trials/size(disc_range, 2))); % test
        config.ResultsFN = []; % test
    else
        [data, config] = VWM_MCS_trials(subject_name, num_trials, disc_range, speed);
    end
    
    if exist('vwm_mcs_data', 'var')
        attempt_num = size(vwm_mcs_data, 2) + 1;
    else
        attempt_num = 1;
    end
    vwm_mcs_data{attempt_num} = data;
    vwm_mcs_config{attempt_num} = config;
    if exist(data_fn, 'file')
        save(data_fn, 'vwm_mcs_data', 'vwm_mcs_config', '-append');
    else
        save(data_fn, 'vwm_mcs_data', 'vwm_mcs_config');
    end
    
    [est_discs q] = analyseVWMMCS(subject_name, attempt_num);
    est_discs = round(est_discs);
end

function c = gen_binornd_correct(p, n)
    tPerS = n / size(p, 2);
    nS = n / tPerS;
    nC = binornd(repmat(tPerS, 1, nS), p);
    
    c = zeros(1, n);
    for i = 1:nS
       for j = 1:tPerS
          if j <= nC(i)
            c((i-1)*tPerS+j) = 1;
          end
       end
    end
end