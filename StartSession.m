function StartSession(subject_name, session_config, num_blocks, data_set)
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
    return
    
    try
        win = MOTWindow();
        for i = 1:num_blocks
            if exist(data_log_fn, 'file')
                data_log_fid = fopen(data_log_fn, 'r');
                if data_log_fid ~= -1
                    [~, count] = fscanf(data_log_fid, '%s');
                    if count >= session_config.session_num
                        session_config.session_num = count + 1;
                    end
                else
                    error('Unable to open data log file %s',data_log_fn);
                end
                fclose(data_log_fid);
            end
            
            startTime = GetSecs;
            config = Initialise_Session(MOT_SessionConfig(win, [subjectName '_' num2str(data_set)], session_config.session_num), session_config);
            if i > 1
                config.doPractice = 0;
            end
            sess = MOT_Session(config, win);
            sess.StartSession();
            endTime = GetSecs;
            save(config.SessionFN, '-APPEND', 'startTime', 'endTime');
            
            % Save data filename to participant's data log
            data_log_fid = fopen(data_log_fn, 'a+');
            if data_log_fid ~= -1
                fprintf(data_log_fid, '%s\n', strrep(config.SessionFN, 'Data/', ''));
            else
                error('Unable to open data log file %s',data_log_fn);
            end
            fclose(data_log_fid);
            
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

function config = Initialise_Session(config, session_config)
    config.Debug = session_config.debug;
    config.InitialSpeed = session_config.InitialSpeed;
    config.doPractice = session_config.doPractice;
    config.doTest = session_config.doTest;
    config.DotWidthScaleFactor = session_config.DotWidthScaleFactor;
    config.MinSepScaleFactor = session_config.MinSepScaleFactor;
    config.DotWidth = round(session_config.DotWidthScaleFactor/config.DegPerPixel);
    config.MinSep = round(session_config.MinSepScaleFactor/config.DegPerPixel); 
    config.InterQuadrantPadding = config.DotWidth/2;
    config.NumTrialsPerCondition = session_config.NumTrialsPerCondition;
    config.NumPracticeTrialsPerCondition = session_config.NumPracticeTrialsPerCondition;
    config.TestConditionTypes = session_config.TestConditionTypes;
    config.NumVWMObjects = session_config.NumVWMObjects;
    config.NumMOTObjects = session_config.NumMOTObjects;
    config.NumMOTTargets = session_config.NumMOTTargets;
    config.VWMObjectColours = session_config.VWMObjectColours;
    config.VWMObjectDisplayTime = session_config.VWMObjectDisplayTime;
end