function [results, stats, subject_names] = analyse(subject_name, sessions)
    if nargin < 1
        subject_name = [];
    end
    if nargin < 2
        sessions = [];
    end
    if isempty(subject_name)
        subject_names = getSubjectNames();
    elseif ~iscellstr(subject_name) && isempty(regexp(subject_name, '[\W]+', 'start')) 
        subject_names{1} = subject_name;
    else
        error('Invalid subject_name: %s\n', subject_name);
    end
    results = {};
    
    for i = 1:size(subject_names, 2)
        results{i} = getResults(subject_names{i});
        if     ismember('session', results{i}.Properties.VariableNames) ...
            && ismember('condition', results{i}.Properties.VariableNames) ...
            && ismember('response_type', results{i}.Properties.VariableNames) ...
            && ismember('correct', results{i}.Properties.VariableNames)
            stats(i) = calcStats(results{i}, sessions);
            graph_session(stats(i), subject_names{i});
        else
            fprintf('%s results table does not contain valid session information. Skipped.\n', subject_names{i});
            stats(i) = struct('t',[], 'sample_size', [], 'avg', [], 'ci', []);
        end
    end
end

function subject_names = getSubjectNames()
    subject_names = {};
    d = dir(['data' filesep '*.mat']);
    for i = 1:size(d, 1)
        data_fn = ['data' filesep d(i).name];
        vars = whos('-file', data_fn);
        if ismember('results', {vars.name})
            [~, name, ~] = fileparts(data_fn);
            subject_names{size(subject_names, 2)+1} = name;
        else
            fprintf('%s does not contain results. Skipped\n', data_fn);
        end
    end
end

function stats = calcStats(results, sessions)
    conditions = [strcmp(results.condition, 'MOT')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'MOT')==1, ...
                  strcmp(results.condition, 'VWM')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'VWM')==1];              
    for i = 1:4
        if isempty(sessions)
            t = results(conditions(:, i), {'correct'});
        else
            idx = zeros(size(results.session));
            for j = sessions
                idx = idx | results.session==j & conditions(:, i);
            end
            t = results(idx, {'correct'});
        end
        stats.t{i} = t;
        stats.sample_size(i) = size(t, 1);
        stats.avg(i) = mean(t{:,:});
        [stats.ci(i,1) stats.ci(i,2)] = calcCI(stats.avg(i), stats.sample_size(i));
    end
end

function results = getResults(subject_name)
    data_fn = ['data' filesep subject_name '.mat'];
    if ~exist(data_fn, 'file')
        error('Could not find %s\n', data_fn);
    end
    load(data_fn, 'results');
    fprintf('Data loaded from %s\n', data_fn);
end

function [u, l] = calcCI(p, n)
    % Calculate 95% confidence interval using Wilson's formula (Wilson 1927)
    % Wilson, E. B. "Probable Inference, the Law of Succession, and Statistical Inference," Journal of the American Statistical Association, 22, 209-212 (1927).
    % See e.g: http://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval#Wilson_score_interval
    % Using this instead of the original formula because it's tolerant to small
    % sample sizes and extreme proportions. For comparison, the original formula was
    % p +- z * sqrt(p*(1-p) / n)
    z = 1.96;
    u = 1/(1 + z^2/n) * (p + z^2/(2*n) + z * sqrt(p*(1-p)/n + z^2/(4*n^2)));
    l = 1/(1 + z^2/n) * (p + z^2/(2*n) - z * sqrt(p*(1-p)/n + z^2/(4*n^2)));
end

function graph_session(stats, subject_name)
    m = stats.avg;
    ci = stats.ci;
    figure('Color','white');
    x = 1:4;
    y = m;
    err(:,1) = ci(:,1) - m';
    err(:,2) = m' - ci(:,2);
    bar(x,y);
    set(gca,'FontName','Times New Roman');
    set(gca,'FontSize',12);
    set(gca,'Color','white');
    box off;
    hold all;
    xlabel(['Observer ' subject_name]);
    ylabel('Mean accuracy (proportion correct)');
    set(gca,'XTickLabel', {'MOT-Only','MOT-Dual', 'VWM-Only','VWM-Dual'});
    h = errorbar(gca,x(:,1),y(:,1), err(1,2), err(1,1));
    set(h,'linestyle','none');
    set(h, 'Color', 'b');
    h = errorbar(gca,x(:,2),y(:,2), err(2,2), err(2,1));
    set(h,'linestyle','none');
    set(h, 'Color', 'b');
    h = errorbar(gca,x(:,3),y(:,3), err(3,2), err(3,1));
    set(h,'linestyle','none');
    set(h, 'Color', 'b');
    h = errorbar(gca,x(:,4),y(:,4), err(4,2), err(4,1));
    set(h,'linestyle','none');
    set(h, 'Color', 'b');
end