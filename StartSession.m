function StartSession(subject_name, num_blocks)
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
    
    if nargin < 2
        num_blocks = 1;
    end
    session_num = 1;
    
    try
        win = MOTWindow();
        %win = MockWin();
        for i = 1:num_blocks
            vars = whos('-file', data_fn);
            data_file_m = matfile(data_fn);
            if ismember('session', {vars.name})
               session_num = size(data_file_m.session, 2) + 1;
            end
            
            config{session_num} = MOT_SessionConfig(win, subject_name, session_num);
            config{session_num}.NumVWMObjects = calibrated_disc_count;
            config{session_num}.InitialSpeed = calibrated_speed;
            if i > 1
                config{session_num}.doPractice = 0;
            end
            config{session_num}.doPractice = 0;
            config{session_num}.Debug = 1;
            config{session_num}.SessionFN = data_fn;
            
            session{session_num} = MOT_Session(config{session_num}, win);
            session{session_num} = session{session_num}.StartSession();
            save(data_fn, '-APPEND', 'config', 'session');
            
            if i < num_blocks
                win.DisplayMessageAndWait('Please press a key to continue with the next block.');
            end
        end
        win.DisplayMessageAndWait('This session is complete.\n\nPlease inform the experimenter.\n\nThank you for your participation so far!');
        delete(win);
    catch
        delete(win);
        ple
    end
end