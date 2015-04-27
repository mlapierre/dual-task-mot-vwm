function [data, config] = VWM_MCS_trials(subject_name, num_trials, disc_range, speed)
% VWM_MCS_trials VWM calibration via the method of constant stimuli
%   VWM calibration
%   subject_name: The name of the participant.
%   num_trials:   The number of trials on which the participant will be tested.
%   disc_range:   The range of number of discs that will be displayed.
%
%   The first stage of calibration should start with the disc_range set to
%   3:7. Use AnalyseVWMMCS to analyse the results. If performance is too
%   inconsistent, or too consistently high or low, the first stage should
%   be repeated with a more suitable range.
%
%   The disc_range for the second stage should be set to according to the 
%   participant's performance during the first stage. It is expected that
%   most participants will perform best when 4 discs are displayed, and so
%   the disc_range for the second stage would most likely be 3:5

    try

        io_ = MOTWindow();
        config = MOT_SessionConfig(io_, 'subject_name', 1);

        % Randomly arrange an equal number of VWM discs
        vwm_objects = repmat(disc_range, 1, num_trials/size(disc_range, 2));
        probeFlags = [zeros(1, num_trials/2) ones(1, num_trials/2)];

        % Generate Trials
        for trial_num = 1:num_trials
            io_.DisplayMessage(sprintf('Loading %d/%d...',trial_num, num_trials));
            config.NumVWMObjects = vwm_objects(trial_num);
            trial = MOT_Trial(config, io_, [TaskType.MOT TaskType.VWM], speed, QuadrantLayout.All, []);
            trial.Condition = Condition.PerformVWM;
            trial.Positions = trial.GeneratePositions();
            trial.ValidProbe = probeFlags(trial_num);
            trial.NumVWMObjects = vwm_objects(trial_num);
            trial.Speed = speed;

            trials(trial_num) = trial;
        end

        trials = Shuffle(trials);
    catch ERROR
        Screen('CloseAll');
        delete(io_);
        rethrow(ERROR);
    end

    % Collect data
    try
        data.trialStart = zeros(1,num_trials);
        data.trialDisplayEnd = zeros(1,num_trials);
        data.trialResponseEnd = zeros(1,num_trials);
        data.correct = zeros(1,num_trials);
        data.num_discs = zeros(1,num_trials);

        startTime = GetSecs;
        for i=1:num_trials
            message = ['Trial ' num2str(i) ' of ' num2str(num_trials) '\n\n'...
                       'Loading...\n\n'];
            io_.DisplayMessage(message);
            save(config.ResultsFN, 'config', 'data');        
            message = ['Trial ' num2str(i) ' of ' num2str(num_trials) '\n\n'...
                       num2str(trials(i).NumVWMObjects) ' objects to remember\n'...
                       'Press any key to begin.\n\n'];
            io_.DisplayMessageAndWait(message);

            data.trialStart(i) = GetSecs;

            [finPos ~] = trials(i).DisplayTrial();
            trials(i).DisplayProbe(finPos, trials(i).ValidProbe);

            data.trialDisplayEnd(i) = GetSecs;

            output = trials(i).GetResponse(finPos, TaskType.VWM, trials(i).ValidProbe);
            data.correct(i) = output.correct;
            data.num_discs(i) = trials(i).NumVWMObjects;

            data.trialResponseEnd(i) = GetSecs;
        end
        endTime = GetSecs;
        save(config.ResultsFN, 'config', 'data');        
        io_.DisplayMessageAndWait('This stage of the experiment is complete, thank you.\nPlease inform the researcher.');
        Screen('CloseAll');
        delete(io_);
    catch ERROR
        Screen('CloseAll');
        delete(io_);
        rethrow(ERROR);
    end
end

