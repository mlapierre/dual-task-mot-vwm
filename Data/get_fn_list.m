function [fn_list, ob_names] = get_fn_list(ob)
    ob_names = {'ML', 'SS', 'ZST', 'AS', 'RY'};
    ob_ids = {'ML1', 'SS1', 'ZST1', 'AS1', 'RY1'};
    
    data_log_fn = sprintf('Data/%s.log', ob_ids{ob});
    data_log_fid = fopen(data_log_fn, 'r');
    if data_log_fid ~= -1
        %fn_list = textscan(data_log_fid, '%s', data_log_fid);
        fn_list = textscan(data_log_fid, '%s', 100, 'CollectOutput', 1);
        fn_list = fn_list{1,1};
    else
        error('Unable to open data log file %s',data_log_fn);
    end
    fclose(data_log_fid);
end