function results = simSession(subject_name)
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file')
        vars = whos('-file', data_fn);
        if ismember('results', {vars.name})
            load(data_fn, 'results');
            fprintf('Data loaded from %s\n', data_fn);
        end
    end
    
    speed_config = 10;
    vwm_discs_config = 8;
    num_blocks = 8;
    num_trials_per_block = 8;
    num_trials = num_blocks * num_trials_per_block;
    cond_names = {'MOT', 'MOT', 'VWM', 'VWM', 'Both', 'Both', 'Both', 'Both'};
    resp_type  = {'MOT', 'MOT', 'VWM', 'VWM', 'MOT', 'VWM', 'MOT', 'VWM'};
    p = [0.75 0.75 0.75 0.75 0.5 0.5 0.5 0.5];

    if exist('results', 'var')
        session_num = max(unique(results.session)) + 1;
    else
        results = table();
        session_num = 1;
    end

    session = repmat(session_num, num_trials, 1);
    speed = repmat(speed_config, num_trials, 1);
    vwm_discs = repmat(vwm_discs_config, num_trials, 1);
    condition = reshape(repmat(cond_names, num_trials_per_block, 1), num_trials, 1);
    response_type = reshape(repmat(resp_type, num_trials_per_block, 1), num_trials, 1);
    valid_probe = reshape(repmat([0 0 0 0 1 1 1 1], num_trials_per_block, 1), num_trials, 1);
    correct = gen_binornd_correct(p, num_trials_per_block)';
    
    results = [results; table(session, condition, correct, response_type, valid_probe, speed, vwm_discs)];
    
    if exist(data_fn, 'file')
        save(data_fn, '-append', 'results');
    else
        save(data_fn, 'results');
    end
end

function c = gen_binornd_correct(p, n)
    nC = binornd(repmat(n, 1, size(p, 2)), p);

    c = zeros(1, n * size(p, 2));
    for i = 1:size(p, 2)
       for j = 1:n
          if j <= nC(i)
            c((i-1)*n+j) = 1;
          end
       end
    end
end