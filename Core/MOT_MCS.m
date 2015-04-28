function est_speed = MOT_MCS(subject_name, num_trials, base_speed, speed_inc)
%   MOT calibration
%   subject_name: The name of the participant.
%   num_trials:   The number of trials on which the participant will be tested.
%   base_speed:   The base speed at which the dots will move, i.e., the speed
%                 at the middle of the range of 5 speeds.
%   speed_inc:    The amount by which the speed increments or decrements for 2
%                 steps above and 2 steps below base_speed.
%                 E.g, if base_speed is 10 and speed_inc is 2 then the
%                 tested speeds will be 6, 8, 10, 12, and 14.
    st = dbstack(1);
    if strcmp(st(1).name, 'StartMOTMCS') ~= true
        if nargin < 1
            subject_name = '';
        end
        [valid, subject_name] = isValidSubjectName(subject_name);
        if ~valid
            return
        end
        fprintf('Participant: %s\n', subject_name);
    end
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file') && ~exist('mot_mcs_data', 'var')
        load(data_fn);
    end
    
    % Set sim = 1 to simulate trials with approximate performance for each 
    % speed as specified below.
    sim = 0;
    if sim == 1
        data.correct = gen_binornd_correct([0.99 0.85 0.75 0.25 0.05], num_trials); % test
        data.speed = sort(repmat(base_speed + (-2*speed_inc:speed_inc:2*speed_inc), 1, num_trials/5)); % test
        config.ResultsFN = []; % test
    else
        [data, config] = MOT_MCS_trials(subject_name, num_trials, base_speed, speed_inc);    
    end
    
    if exist('mot_mcs_data', 'var')
        attempt_num = size(mot_mcs_data, 2) + 1;
    else
        attempt_num = 1;
    end
    mot_mcs_data{attempt_num} = data;
    mot_mcs_config{attempt_num} = config;
    if exist(data_fn, 'file')
        save(data_fn, 'mot_mcs_data', 'mot_mcs_config', '-append');
    else
        save(data_fn, 'mot_mcs_data', 'mot_mcs_config');
    end
    [est_speed q] = analyseMOTMCS(subject_name, attempt_num);
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