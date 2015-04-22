function [data, config] = MOT_MCS_trials(subject_name, num_trials, base_speed, speed_inc)
% MOT_MCS_trials MOT calibration via the method of constant stimuli
%   MOT calibration
%   subject_name: The name of the participant.
%   num_trials:   The number of trials on which the participant will be tested.
%   base_speed:   The base speed at which the dots will move, i.e., the speed
%                 at the middle of the range of 5 speeds.
%   speed_inc:    The amount by which the speed increments or decrements.
%                 E.g, if base_speed is 10 and speed_inc is 2 then the
%                 tested speeds will be 6, 8, 10, 12, and 14.
%
%   The first stage of calibration should start with the base_speed set to
%   10, or higher if the participant has played a lot of action video
%   games. Use AnalyseMOTMCS to analyse the results. If performance is too
%   inconsistent, or too consistently high or low, the first stage should
%   be repeated with a more suitable base speed.
%
%   The speed_inc for the second stage should be set to 1, and the
%   base_speed will depend on the participant's performance during the
%   first stage.

    try
        io_ = MOTWindow();
        config = MOT_SessionConfig(io_, subject_name, 1);
        %DotWidthScaleFactor = 0.6;
        %MinSepScaleFactor = 0.8;
        %config.DotWidth = round(DotWidthScaleFactor/config.DegPerPixel);
        %config.MinSep = round(MinSepScaleFactor/config.DegPerPixel); 
        %config.NumMOTObjects = 10;
        %config.NumMOTTargets = 5;

        %num_trials = 10;
        %base_speed = 10;
        %speed_inc = 2;
        speedLevels = -2*speed_inc:speed_inc:2*speed_inc;

        % Distribute speeds and expected responses evenly across trials
        speeds = repmat(speedLevels + base_speed, 1, num_trials/size(speedLevels,2));
        probeFlags = [zeros(num_trials/2,1); ones(num_trials/2,1)];

        % Generate Trials
        for trial_num = 1:num_trials
            io_.DisplayMessage(sprintf('Loading %d/%d...',trial_num, num_trials));
            trial = MOT_Trial(config, io_, [TaskType.MOT TaskType.VWM], speeds(trial_num), QuadrantLayout.All, []);
            trial.Condition = Condition.PerformMOT;
            trial.Positions = trial.GeneratePositions();
            trial.ValidProbe = probeFlags(trial_num);
            trial.Speed = speeds(trial_num);

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
        data.speed = zeros(1,num_trials);

        data.startTime = GetSecs;
        for i=1:num_trials
            message = ['Trial ' num2str(i) ' of ' num2str(num_trials) '\n\n'...
                       'Loading...\n\n'];
            io_.DisplayMessage(message);
            save(config.ResultsFN, 'config', 'data');        
            message = ['Trial ' num2str(i) ' of ' num2str(num_trials) '\n\n'...
                       'Press any key to begin.\n\n'];
            io_.DisplayMessageAndWait(message);

            data.trialStart(i) = GetSecs;

            [finPos ~] = trials(i).DisplayTrial();
            trials(i).DisplayProbe(finPos, trials(i).ValidProbe);

            data.trialDisplayEnd(i) = GetSecs;

            output = trials(i).GetResponse(finPos, TaskType.VWM, trials(i).ValidProbe);
            data.correct(i) = output.correct;

            data.speed(i) = trials(i).Speed;
            data.trialResponseEnd(i) = GetSecs;
        end
        data.endTime = GetSecs;
        save(config.ResultsFN, 'config', 'data');        
        io_.DisplayMessageAndWait('This stage of the experiment is complete, thank you.\nPlease inform the researcher so you can begin the next stage.');
        Screen('CloseAll');
        delete(io_);
    catch ERROR
        Screen('CloseAll');
        delete(io_);
        rethrow(ERROR);
    end
end