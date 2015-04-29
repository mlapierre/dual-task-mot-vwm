function StartSession(subject_name, num_sessions, num_trials_per_condition)
    clearvars -except subject_name num_sessions num_trials_per_condition;

    view_params = [38.5 60]; % screen width and viewing distance
    
    KbName('UnifyKeyNames');
    if nargin < 1 || isempty(subject_name)
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

    if ~isCalibrationComplete(data_fn, 'MOT')
        fprintf('\nMOT calibration has not been completed\n');
        StartMOTMCS(subject_name);
        load(data_fn);
    else
        fprintf('MOT calibration has been completed\n');
    end
    
    if ~isCalibrationComplete(data_fn, 'VWM')
        fprintf('\nVWM calibration has not been completed\n');
        StartVWMMCS(subject_name);
        load(data_fn);
    else
        fprintf('VWM calibration has been completed\n');
    end
  
    [calibrated_speed, calibrated_disc_count] = getCalibratedParams(data_fn);
    
    if nargin < 2 || isempty(num_sessions)
        num_sessions = 1;
    end
    session_num = 1;
    
    if nargin < 3 || isempty(num_trials_per_condition)
        num_trials_per_condition = 16;
    end
    
    try
        for i = 1:num_sessions
            vars = whos('-file', data_fn);
            data_file_m = matfile(data_fn);
            if ismember('session', {vars.name})
               session_num = size(data_file_m.session, 2) + 1;
            end
            
            fprintf('Ready to begin session %d with speed at %f and disc count at %d\n', ...
                session_num, calibrated_speed, calibrated_disc_count);
            fprintf('Press any key to begin\n');
            GetKbChar();

            win = MOTWindow();
            %win = MockWin();
            config = MOT_SessionConfig(win, subject_name, session_num, view_params);
            config.NumTrialsPerCondition = num_trials_per_condition;
            config.NumPracticeTrialsPerCondition = 8;
            config.NumVWMObjects = calibrated_disc_count;
            config.InitialSpeed = calibrated_speed;
            if i > 1
                config.doPractice = 0;
            end
            config.Debug = 0;
            
            new_sess = MOT_Session(config, win);
            new_sess = new_sess.StartSession();
            
            session{session_num} = new_sess;
            save(data_fn, '-APPEND', 'session');
            
            if ~exist('results', 'var')
                results = table();
            end
            results = [results; tidySessionData(new_sess.TestResults, session_num)];
            save(data_fn, '-append', 'results');

            if i < num_sessions
                win.DisplayMessageAndWait('Please press a key to continue with the next session.');
            end
        end
        win.DisplayMessageAndWait('This session is complete.\n\nPlease inform the experimenter.\n\nThank you for your participation so far!');
        delete(win);
    catch
        delete(win);
        ple
    end
end