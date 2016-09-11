function StartMOTMCS(subject_name)
    KbName('UnifyKeyNames');
    
    st = dbstack(1);
    if strcmp(st(1).name, 'StartSession') ~= true
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
            fprintf('Data and config loaded from %s\n', data_fn);
        else
            fprintf('%s has not participated in this experiment before\n', subject_name);
            fprintf('Saving data and config to: %s\n', data_fn);
        end
        
        if exist('mot_mcs_data', 'var')
            nAttempts = size(mot_mcs_data, 2);
            if isfield(mot_mcs_data{nAttempts}, 'speedFinal')
                fprintf('MOT calibration has been completed\n');
                return
            end
        end
        fprintf('\nMOT calibration has not been completed\n');
    end
    
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file')
        load(data_fn);
    end
    
    %ListenChar(2);
    fprintf('Please press a key to begin the first stage...\n');
    GetKbChar();
    speed = MOT_MCS(subject_name, 50, 10, 2);

    fprintf('Please press ''y'' to begin the second stage, or any other key to quit...\n');
    char = GetKbChar();
    if char ~= 'y'
        %ListenChar(0);
        return
    end
    MOT_MCS(subject_name, 50, speed, 1);

    fprintf('Estimating final threshold based on last 2 attempts...\n');
    load(data_fn);
    nAttempts = size(mot_mcs_data, 2);
    [mot_mcs_data{nAttempts}.speedFinal mot_mcs_data{nAttempts}.qFinal] = analyseMOTMCS(subject_name, [nAttempts nAttempts-1]);
    
    save(data_fn, 'mot_mcs_data', 'mot_mcs_config', '-append');
    %ListenChar(0);
end