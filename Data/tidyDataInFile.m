function tidyDataInFile(subject_name)
    data_fn = ['data' filesep subject_name '.mat'];
    if ~exist(data_fn, 'file')
        fprintf('Could not find %s\n', data_fn);
        return
    end
    load(data_fn);
    fprintf('Data loaded from %s\n', data_fn);

    results = table();
    for i = 1:size(session, 2)
        results = [results; tidySessionData(session{i}.TestResults, i)];
    end
    save(data_fn, '-append', 'results');
    fprintf('Updated file with results table\n');
end