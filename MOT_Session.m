%
% Coordinates the execution of a session, organising trials into blocks and phases (e.g, practise vs. QUEST vs test).
%
classdef MOT_Session < Session
    properties
    end % properties
    
    methods
        function obj = MOT_Session(conf, window)
            obj = obj@Session(conf, window);
        end
        
        % Coordinates and displays the trials for the current session.
        % Results are saved after each trial. QUEST results are saved
        function obj = StartSession(obj)
            obj.SessionStartTime = GetSecs;
            
            if obj.Config.doPractice
                disp('Begin practice phase');
                obj = obj.ExecutePracticePhase(obj.Config.TaskTypes);
            end

            if obj.Config.doTest
                disp('Begin test phase');
                disp(obj.Config.SessionNum);
                obj.Config.TestConditionTypes = circshift(obj.Config.TestConditionTypes, [0 obj.Config.SessionNum-1]);
                obj.Config.TestConditionTypes = [obj.Config.TestConditionTypes fliplr(obj.Config.TestConditionTypes)];
                disp(obj.Config.TestConditionTypes);
                obj.Config.NumTrialsPerCondition = obj.Config.NumTrialsPerCondition/2;
                obj = obj.ExecuteTestPhase(obj.Config.TaskTypes);
            end
            obj.SessionEndTime = GetSecs;
        end % function StartSession(obj)

        % %%%%%%%%%%%%%%
        % Practice Phase
        %
        function obj = ExecutePracticePhase(obj, taskTypes)
            % Reduce the length of each trial for this practice phase
            oldTime = obj.Config.TimeTrialTotal;
            obj.Config.TimeTrialTotal = obj.Config.TrialTimePractice;
            obj.Config.NumFrames = round(obj.Config.TimeTrialTotal / obj.Win.InterFrameInterval);            
            
            totalTrials = size(obj.Config.PracticeConditionTypes, 2) * obj.Config.NumPracticeTrialsPerCondition;
            phase = 'practice';
            
            old_mot_feedback = obj.Config.ProvideMOTFeedback;
            old_vwm_feedback = obj.Config.ProvideVWMFeedback;
            obj.Config.ProvideMOTFeedback = 1;
            obj.Config.ProvideVWMFeedback = 1;

            % Display each condition blocked
            for i=1:size(obj.Config.PracticeConditionTypes, 2)
                message = obj.GetInstructions(phase, obj.Config.PracticeConditionTypes(i), obj.Config.NumMOTTargets, obj.Config.NumMOTObjects, obj.Config.NumVWMObjects);
                obj.Win.DisplayMessageAndWaitForKey([message 'Please press ''t'' to begin.'], 't');
                
                MOTValidProbe = [zeros(obj.Config.NumPracticeTrialsPerCondition/4,1); ones(obj.Config.NumPracticeTrialsPerCondition/4,1)];
                VWMValidProbe = MOTValidProbe;
                task_to_respond_to_flags = [zeros(obj.Config.NumPracticeTrialsPerCondition/2,1); ones(obj.Config.NumPracticeTrialsPerCondition/2,1)];
                task_to_respond_to_flags(task_to_respond_to_flags == 0) = TaskType.MOT;
                task_to_respond_to_flags(task_to_respond_to_flags == 1) = TaskType.VWM;
                probe_is_valid = [MOTValidProbe; VWMValidProbe];
                flags_index = Shuffle(1:obj.Config.NumPracticeTrialsPerCondition);
                
                for trial_num=1:obj.Config.NumPracticeTrialsPerCondition;
                    trial = MOT_Trial(obj.Config, obj.Win, taskTypes, obj.Config.InitialSpeed-1, QuadrantLayout.All, []);
                    trial.Condition = obj.Config.PracticeConditionTypes(i);
                    [pos] = trial.GeneratePositions();
                    trial.Positions = pos;
                    
                    if obj.Config.Debug == 1
                        message = sprintf('Condition: %s\n',Condition.GetName(trial.Condition));
                    else
                        message = '';
                    end
                    message = [message 'Block ' num2str(i) ' of ' num2str(size(obj.Config.PracticeConditionTypes, 2)) '\n'...
                               'Trial ' num2str(trial_num) ' of ' num2str(obj.Config.NumPracticeTrialsPerCondition) '\n\n'...
                               'Press any key to begin.\n\n'];
                    obj.Win.DisplayMessageAndWait(message);

                    % Display stimuli
                    trialStart = GetSecs;
                    [finPos missedFrames] = trial.DisplayTrial();
                    trialDisplayEnd = GetSecs;
                    trial.DisplayProbe(finPos, probe_is_valid(flags_index(trial_num)));
                    trialProbeDisplayEnd = GetSecs;
                    
                    % Get response
                    output = trial.GetResponse(finPos, task_to_respond_to_flags(flags_index(trial_num)), probe_is_valid(flags_index(trial_num)));
                    trialResponseEnd = GetSecs;
                    obj.Win.DisplayMessage('Loading, please wait...');
                    
                    obj.PracticeResults(i, trial_num).Condition = obj.Config.PracticeConditionTypes(i);
                    obj.PracticeResults(i, trial_num).TrialStart = trialStart;
                    obj.PracticeResults(i, trial_num).TrialDisplayEnd = trialDisplayEnd;
                    obj.PracticeResults(i, trial_num).TrialProbeDisplayEnd = trialProbeDisplayEnd;
                    obj.PracticeResults(i, trial_num).TrialResponseEnd = trialResponseEnd;
                    obj.PracticeResults(i, trial_num).Correct = output.correct;
                    obj.PracticeResults(i, trial_num).ProbeMessageDisplayTime = output.probe_message_display_time;
                    obj.PracticeResults(i, trial_num).ProbeMessageResponseTime = output.probe_message_response_time;
                    obj.PracticeResults(i, trial_num).ValidProbe = probe_is_valid(flags_index(trial_num));
                    obj.PracticeResults(i, trial_num).TaskType = task_to_respond_to_flags(flags_index(trial_num));
                    obj.PracticeResults(i, trial_num).MissedFrames = missedFrames;
                    obj.PracticeResults(i, trial_num).Positions = pos;
                    obj.PracticeResults(i, trial_num).Speed = obj.Config.InitialSpeed-1;

                    obj.SaveResults(obj.PracticeResults);
                end
            end
            obj.SaveSession();
            obj.Config.TimeTrialTotal = oldTime;
            obj.Config.NumFrames = round(obj.Config.TimeTrialTotal / obj.Win.InterFrameInterval);            
            obj.Config.ProvideMOTFeedback = old_mot_feedback;
            obj.Config.ProvideVWMFeedback = old_vwm_feedback;
        end % End ExecutePracticePhase
        
        % %%%%%%%%%%
        % Test phase
        function obj = ExecuteTestPhase(obj, taskTypes)
            totalTrials = size(obj.Config.TestConditionTypes, 1) * obj.Config.NumTrialsPerCondition;
            trialNum = 1;
            phase = 'test';
            % Display each condition blocked
            for i=1:size(obj.Config.TestConditionTypes, 2)
                message = obj.GetInstructions(phase, obj.Config.TestConditionTypes(i), obj.Config.NumMOTTargets, obj.Config.NumMOTObjects, obj.Config.NumVWMObjects);

                MOTValidProbe = [zeros(obj.Config.NumTrialsPerCondition/4,1); ones(obj.Config.NumTrialsPerCondition/4,1)];
                VWMValidProbe = MOTValidProbe;
                task_to_respond_to_flags = [zeros(obj.Config.NumTrialsPerCondition/2,1); ones(obj.Config.NumTrialsPerCondition/2,1)];
                task_to_respond_to_flags(task_to_respond_to_flags == 0) = TaskType.MOT;
                task_to_respond_to_flags(task_to_respond_to_flags == 1) = TaskType.VWM;
                probe_is_valid = [MOTValidProbe; VWMValidProbe];
                flags_index = Shuffle(1:obj.Config.NumTrialsPerCondition);
                
                obj.Win.DisplayMessageAndWaitForKey([message 'Please press ''t'' to begin.'], 't');                
                for trial_num=1:obj.Config.NumTrialsPerCondition;
                    trial = MOT_Trial(obj.Config, obj.Win, taskTypes, obj.Config.InitialSpeed, QuadrantLayout.All, []);
                    trial.Condition = obj.Config.TestConditionTypes(i);
                    [pos] = trial.GeneratePositions();
                    trial.Positions = pos;
                    
                    if obj.Config.Debug == 1
                        message = sprintf('Condition: %s\n',Condition.GetName(trial.Condition));
                    else
                        message = '';
                    end
                    message = [message 'Block ' num2str(i) ' of ' num2str(size(obj.Config.TestConditionTypes, 2)) '\n'...
                               'Trial ' num2str(trial_num) ' of ' num2str(obj.Config.NumTrialsPerCondition) '\n\n'...
                               'Press any key to begin.\n\n'];
                    obj.Win.DisplayMessageAndWait(message);

                    % Display stimuli
                    trialStart = GetSecs;
                    [finPos missedFrames] = trial.DisplayTrial();
                    trialDisplayEnd = GetSecs;
                    trial.DisplayProbe(finPos, probe_is_valid(flags_index(trial_num)));
                    trialProbeDisplayEnd = GetSecs;
                    
                    % Get response
                    output = trial.GetResponse(finPos, task_to_respond_to_flags(flags_index(trial_num)), probe_is_valid(flags_index(trial_num)));
                    trialResponseEnd = GetSecs;
                    obj.Win.DisplayMessage('Loading, please wait...');

                    obj.TestResults(i, trial_num).Condition = obj.Config.TestConditionTypes(i);
                    obj.TestResults(i, trial_num).TaskTypes = taskTypes;
                    obj.TestResults(i, trial_num).TrialStart = trialStart;
                    obj.TestResults(i, trial_num).TrialDisplayEnd = trialDisplayEnd;
                    obj.TestResults(i, trial_num).TrialProbeDisplayEnd = trialProbeDisplayEnd;
                    obj.TestResults(i, trial_num).TrialResponseEnd = trialResponseEnd;
                    obj.TestResults(i, trial_num).Correct = output.correct;
                    obj.TestResults(i, trial_num).ProbeMessageDisplayTime = output.probe_message_display_time;
                    obj.TestResults(i, trial_num).ProbeMessageResponseTime = output.probe_message_response_time;
                    obj.TestResults(i, trial_num).ValidProbe = probe_is_valid(flags_index(trial_num));
                    obj.TestResults(i, trial_num).TaskType = task_to_respond_to_flags(flags_index(trial_num));
                    obj.TestResults(i, trial_num).MissedFrames = missedFrames;
                    obj.TestResults(i, trial_num).Positions = pos;
                    obj.TestResults(i, trial_num).Speed = obj.Config.InitialSpeed;

                    obj.SaveResults(obj.TestResults);
                    % Retain the Window object to enable testing automation
                    obj.Win = trial.Window;
                end
            end            
            obj.SaveSession();
        end
        
        function message = GetInstructions(obj, phase, condition, num_mot_targets, num_mot_objects, num_vwm_objects)
            if strcmp(phase, 'practice')
                message = 'Practice phase\n\n';
            else
                message = 'Test phase\n\n';
            end
            message = sprintf('%sYou''ll see %d dots. There will be %d coloured dots and %d black dots.',...
                message, num_vwm_objects + num_mot_objects, num_vwm_objects, num_mot_objects);

            if condition == Condition.PerformVWM
                message = [message '\nYour task is to remember the colour and location '...
                    'of each coloured dot.\n\n'...
                    'The black dots will begin moving after a moment. Please ignore them.\n\n'...
                    'Once the dots stop moving one of the static dots will be coloured again. '...
                    'You''ll be asked if you saw a dot of that colour in that position before.\n'...
                    'Respond ''y'' only if the dot is '...
                    'both the same colour and in the same position as you remember.\n'...
                    'Guess if you''re unsure.\n\n'];
            elseif condition == Condition.PerformMOT
                message = sprintf(['%s\nPlease ignore the coloured dots.\n\n'...
                    'You will see white circles around %d of the black dots. '...
                    'Your task is to track those %d target dots.\n\n'...
                    'The dots will begin moving, except for the coloured dots. After a few moments '...
                    'the white circles will disappear and the static coloured dots will turn black. '...
                    'Keep tracking the same %d moving targets.\n\n'...
                    'Once the dots stop moving one dot will be circled and you''ll be asked if it was a target. '...
                    'Press ''y'' if it was, otherwise press ''n''.\n'...
                    'Guess if you''re unsure.\n\n'],...
                    message, num_mot_targets, num_mot_targets, num_mot_targets);
            elseif condition == Condition.PerformBoth
                message = sprintf(['%s\nYour task is to remember the colour and location ',...
                    'of each coloured dot.\n\n',...
                    'You will see white circles around %d of the black dots. ',...
                    'Your task is also to track those %d target dots.\n\n',...
                    'The dots will begin moving, except for the coloured dots. After a few moments ',...
                    'the white circles will disappear and the static coloured dots will turn black. ',...
                    'Keep tracking the same %d moving targets.\n\n',...
                    'Once the dots stop moving one dot will be circled and you may be asked if it was a target. '...
                    'Press ''y'' if it was, otherwise press ''n''.\n'...
                    'Alternatively, one of the static dots will be coloured again and ',...
                    'you may be asked if you saw a dot of that colour in that position before.\n',...
                    'Respond ''y'' only if the dot is ',...
                    'both the same colour and in the same position as you remember.\n',...
                    'Guess if you''re unsure.\n\n'],...
                    message, num_mot_targets, num_mot_targets, num_mot_targets);
            end
        end

        
        function isSingleTask = IsSingleTask(obj, condition)
            if find(condition == Condition.SingleTask)
                isSingleTask = 1;
            else
                isSingleTask = 0;
            end
        end
            end % methods
end % classdef