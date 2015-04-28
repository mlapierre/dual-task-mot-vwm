function [complete] = isCalibrationComplete(data_fn, type)
    complete = 0;
    if ~exist(data_fn, 'file')
        return
    end
    
    vars = whos('-file', data_fn);
    m = matfile(data_fn);
    
    if strcmp(type, 'MOT') == 1 && ismember('mot_mcs_data', {vars.name})
        data = m.mot_mcs_data;
        nAttempts = size(data, 2);
        if isfield(data{nAttempts}, 'speedFinal')
            complete = 1;
        end
    end
    if  strcmp(type, 'VWM') == 1 && ismember('vwm_mcs_data', {vars.name})
        data = m.vwm_mcs_data;
        nAttempts = size(data, 2);
        if isfield(data{nAttempts}, 'disc_count_final')
            complete = 1;
        end
    end
end