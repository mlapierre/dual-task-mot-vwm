function StartSession(subjectName, session_config, num_blocks, data_set)
    win = MOTWindow();
    %win = MockWin();
    try
        data_log_fn = sprintf('Data/%s.log', subjectName);
        for i = 1:num_blocks
            % Determine the appropriate session number
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