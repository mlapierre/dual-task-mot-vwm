clear all;

io_ = MOTWindow();
config = MOT_SessionConfig(io_, 'as1_vwm_mcs_1', 1);
DotWidthScaleFactor = 0.6;
MinSepScaleFactor = 0.8;
config.DotWidth = round(DotWidthScaleFactor/config.DegPerPixel);
config.MinSep = round(MinSepScaleFactor/config.DegPerPixel); 
config.NumMOTObjects = 10;
config.NumMOTTargets = 5;

numTrials = 60;
initialStim = 4;
speed = 16;

index = Shuffle(1:numTrials);

stim_inc = 1;
stimLevels = [initialStim - stim_inc...
                initialStim ...
                initialStim + stim_inc...
                ];
% Randomly arrange an equal number of each stimLevel
% For each stimLevel, there should be an equal number of changes (i.e., 50% change, %50 no change)
vwm_objects = repmat(stimLevels, 1, numTrials/size(stimLevels,2));
%speeds = speeds(:,index);

% determine for each trial whether the MOT probe is a target
vwmProbeFlags = [zeros(numTrials/2,1); ones(numTrials/2,1)];
%probeFlags = [1 1 1 1 1];
probeFlags = Shuffle(vwmProbeFlags);

%% Generate Trials

for trial_num = 1:numTrials
    io_.DisplayMessage(sprintf('Loading %d/%d...',trial_num, numTrials));
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

%% Collect data
try
    trialStart = zeros(1,numTrials);
    trialDisplayEnd = zeros(1,numTrials);
    trialResponseEnd = zeros(1,numTrials);
    correct = zeros(1,numTrials);
    speed = zeros(1,numTrials);
    
    startTime = GetSecs;
    for i=1:numTrials
        message = ['Trial ' num2str(i) ' of ' num2str(numTrials) '\n\n'...
                   'Loading...\n\n'];
        io_.DisplayMessage(message);
        save(config.ResultsFN, 'correct','vwm_objects', 'speed', 'trials', 'trialStart', 'trialDisplayEnd', 'trialResponseEnd');        
        message = ['Trial ' num2str(i) ' of ' num2str(numTrials) '\n\n'...
                   num2str(trials(i).NumVWMObjects) ' objects to remember\n'...
                   'Press any key to begin.\n\n'];
        io_.DisplayMessageAndWait(message);

        trialStart(i) = GetSecs;
        
        [finPos missedFrames] = trials(i).DisplayTrial();
        trials(i).DisplayProbe(finPos, trials(i).ValidProbe);
        
        trialDisplayEnd(i) = GetSecs;
        
        output = trials(i).GetResponse(finPos, TaskType.VWM, trials(i).ValidProbe);
        correct(i) = output.correct;
        
        trialResponseEnd(i) = GetSecs;
    end
    endTime = GetSecs;
    save(config.SessionFN, 'config','trials','correct','vwm_objects','startTime','endTime','trialStart', 'trialDisplayEnd', 'trialResponseEnd');
    if exist(config.SessionFN, 'file') && exist(config.ResultsFN, 'file')
        delete(config.ResultsFN);
    end
    io_.DisplayMessageAndWait('This stage of the experiment is complete, thank you.\nPlease inform the researcher.');
    
    %[s q] = CalcThreshold([results.Speed], [results.MOTCorrect], 0.75, .5)
    Screen('CloseAll');
    delete(io_);
catch ERROR
    Screen('CloseAll');
    delete(io_);
    rethrow(ERROR);
end