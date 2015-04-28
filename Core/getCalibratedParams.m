function [calibrated_speed, calibrated_disc_count] = getCalibratedParams(data_fn)
    calibrated_speed = [];
    calibrated_disc_count = [];
    vars = whos('-file', data_fn);
    m = matfile(data_fn);
    
    if ismember('mot_mcs_data', {vars.name})
        data = m.mot_mcs_data;
        nAttempts = size(data, 2);
        if isfield(data{nAttempts}, 'speedFinal')
            calibrated_speed = data{nAttempts}.speedFinal;
        end
    end
    if ismember('vwm_mcs_data', {vars.name})
        data = m.vwm_mcs_data;
        nAttempts = size(data, 2);
        if isfield(data{nAttempts}, 'disc_count_final')
            calibrated_disc_count = data{nAttempts}.disc_count_final;
        end
    end
end