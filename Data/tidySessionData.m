function results = tidySessionData(session_data, session_num)
    num_blocks = size(session_data, 1);
    num_trials_per_block = size(session_data, 2);
    num_trials = num_blocks * num_trials_per_block;

    a = reshape([session_data.Condition], num_blocks, num_trials_per_block);
    b = reshape(a', num_trials, 1);
    condition = cell(num_trials, 1);
    at = reshape([session_data.TaskType], num_blocks, num_trials_per_block);
    bt = reshape(at', num_trials, 1);
    response_type = cell(num_trials, 1);
    for i = 1:size(b, 1)
        switch b(i)
            case 1
                condname = 'MOT';
            case 2
                condname = 'VWM';
            case 3
                condname = 'Both';
        end
        condition{i} = condname;
        if strcmp(condname, 'Both') == 1
            switch bt(i)
                case 2
                    name = 'MOT';
                case 3
                    name = 'VWM';
            end
            response_type{i} = name;
        else
            response_type{i} = condname;
        end
    end

    a = reshape([session_data.Correct], num_blocks, num_trials_per_block);
    correct = reshape(a', num_trials, 1);

    a = reshape([session_data.ValidProbe], num_blocks, num_trials_per_block);
    valid_probe = reshape(a', num_trials, 1);

    a = reshape([session_data.Speed], num_blocks, num_trials_per_block);
    speed = reshape(a', num_trials, 1);

    a = reshape([session_data.NumVWMObjects], num_blocks, num_trials_per_block);
    vwm_discs = reshape(a', num_trials, 1);

    session = repmat(session_num, num_trials, 1);

    results = table(session, condition, correct, response_type, valid_probe, speed, vwm_discs);
end    