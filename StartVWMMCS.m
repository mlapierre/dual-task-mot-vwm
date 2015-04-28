function StartVWMMCS(subject_name)
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
            load(data_fn);
            fprintf('Data and config loaded from %s\n', data_fn);
        else
            fprintf('%s has not participated in this experiment before\n', subject_name);
            fprintf('Saving data and config to: %s\n', data_fn);
        end
        if exist('vwm_mcs_data', 'var')
            nAttempts = size(vwm_mcs_data, 2);
            if isfield(vwm_mcs_data{nAttempts}, 'disc_count_final')
                fprintf('VWM calibration has been completed\n');
                return
            end
        end
        fprintf('\nVWM calibration has not been completed\n');
    end
    
    data_fn = ['data' filesep subject_name '.mat'];
    if exist(data_fn, 'file')
        load(data_fn);
    end
    
    if ~exist('mot_mcs_data', 'var')
        fprintf('MOT calibration has not been completed. Please do so first before attempting VWM calibration\n');
        return
    end
    
    nAttempts = size(mot_mcs_data, 2);
    speed = mot_mcs_data{nAttempts}.speedFinal;

    ListenChar(2);
    fprintf('As per MOT calibration, MOT discs will move at speed %f\n', speed);
    fprintf('If this is correct, please press ''y'' to begin the first stage, otherwise press ''n'' to enter a different speed...\n');
    char = GetKbChar();
    if char == 'n'
        ListenChar(0);
        speed = input('Please enter the correct speed: ');
        ListenChar(2);
        fprintf('MOT discs will move at speed %f\n', speed);
    end
    disc_count = VWM_MCS(subject_name, 50, 3:7, speed);
    if disc_count < 3
        fprintf('In the next stage the disc count cannot be less than 3. The participant may require practice to reach the expected level of performance.\n');
    end
    if disc_count < 4
        disc_count = 4;
    end
    
    fprintf('Please press ''y'' to begin the second stage, or any other key to quit...\n');
    char = GetKbChar();
    if char ~= 'y'
        ListenChar(0);
        return
    end
    VWM_MCS(subject_name, 60, disc_count-1:disc_count+1, speed);

    fprintf('Estimating final threshold based on last 2 attempts...\n');
    load(data_fn);
    nAttempts = size(vwm_mcs_data, 2);
    [disc_count vwm_mcs_data{nAttempts}.qFinal] = analyseVWMMCS(subject_name, [nAttempts nAttempts-1]);
    if disc_count < 3
        fprintf('Disc count cannot be less than 3. The participant may require practice to reach the expected level of performance.\n');
        disc_count = 3;
    end
    
    vwm_mcs_data{nAttempts}.disc_count_final = round(disc_count);
    save(data_fn, 'vwm_mcs_data', 'vwm_mcs_config', '-append');
    ListenChar(0);
end