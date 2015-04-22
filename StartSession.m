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
    
    if exist('config_mot_mcs', 'var')
        fprintf('MOT calibration has been completed\n');
    else
        fprintf('\nMOT calibration has not been completed\n');
        fprintf('Please press a key to begin the first stage...\n');
        GetKbChar();
        [ mot_mcs1_data, mot_mcs1_config ] = MOT_MCS(subject_name, 50, 10, 2);
        fprintf('Estimating threshold...\n');
        [speed mot_mcs1_data.q1] = CalcThreshold([mot_mcs1_data.speed], [mot_mcs1_data.correct], 0.75, .5);
        save(data_fn, 'mot_mcs1_data', 'mot_mcs1_config');
        if exist(mot_mcs1_config.ResultsFN, 'file')
            delete(mot_mcs1_config.ResultsFN);
        end
        
        fprintf('Please press a key to begin the second stage...\n');
        GetKbChar();
        [ mot_mcs2_data, mot_mcs2_config ] = MOT_MCS(subject_name, 50, speed, 1);
        fprintf('Estimating final threshold...\n');
        [speed mot_mcs1_data.q2] = CalcThreshold([mot_mcs1_data.speed mot_mcs2_data.speed],...
                                                 [mot_mcs1_data.correct mot_mcs2_data.correct], 0.7, .5);
        save(data_fn, 'mot_mcs2_data', 'mot_mcs2_config', '-append');
        if exist(mot_mcs1_config.ResultsFN, 'file')
            delete(mot_mcs1_config.ResultsFN);
        end

        return 
    end
    
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