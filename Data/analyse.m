function [raw_data, stats, anovatab] = analyse(subject_name, sessions)
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
    raw_data = {};
    
    for i = 1:size(subject_names, 2)
        raw_data{i} = getResults(subject_names{i});
        if     ismember('session', raw_data{i}.Properties.VariableNames) ...
            && ismember('condition', raw_data{i}.Properties.VariableNames) ...
            && ismember('response_type', raw_data{i}.Properties.VariableNames) ...
            && ismember('correct', raw_data{i}.Properties.VariableNames)
            stats_tmp = calcStats(raw_data{i}, sessions);
            stats_tmp.name = subject_names{i};
            stats(i) = stats_tmp;
        else
            fprintf('%s results table does not contain valid session information. Skipped.\n', subject_names{i});
            stats(i) = struct('sample_size', [], 'avg', [], 'ci', [], 'comparisons', [], 'name', subject_names{i});
        end
    end
    
    if size(subject_names, 2) > 1
        % Remove empty results sets
        graph_stats = stats;
        idx = arrayfun(@(x)(isempty(x.avg)), stats);
        graph_stats(idx) = [];
        graph_subject_names = subject_names;
        graph_subject_names(idx) = [];

        [graph_stats(size(graph_stats, 2) + 1), anovatab] = calcGroupStats(graph_stats);
        graph_subject_names{size(graph_subject_names, 2) + 1} = 'Group';
        graph_all(graph_stats, graph_subject_names);
        
        stats_tmp = graph_stats(size(graph_stats, 2));
        stats_tmp.name = 'Group';
        stats(i) = stats_tmp;
    else
        graph_session(stats(1), subject_names{1});
        anovatab = {};
    end
    stats = orderfields(stats, [5, 2, 3, 4, 1]);
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

function [stats, anovatab] = calcGroupStats(graph_stats)
    nC = size(graph_stats(1).avg, 2);
    m = reshape([graph_stats.avg], nC, size(graph_stats, 2));
    n = size(m, 2);
    
    % Calculate 95% confidence interval as per:
    % Morey, R. D. (2008). Confidence Intervals from Normalized Data: A correction to Cousineau (2005).
    %   Tutorials in Quantitative Methods for Psychology, 4, 61-64. 
    m(:, n + 1) = mean(m, 2);
    norm = (m(:, 1:n) - repmat(mean(m(:,1:n)), nC, 1)) + mean(mean(m(:, 1:n)));
    v = sqrt(std(norm,0,2));
    sd = v.^2 *(nC/(nC-1));
    sem = sd/sqrt(n);
    stats.sample_size = repmat(n, 1, nC);
    stats.avg = m(:, n + 1)';
    stats.ci = [m(:, n + 1)-sem*1.96 m(:, n + 1)+sem*1.96];

    % Two-way ANOVA
    x = repmat(1:n, nC, 1);
    X = [m(1,1:n) m(3,1:n); m(2,1:n) m(4,1:n)]';
    [~,anovatab,~] = anova2(X, n, 'off');
    anovatab{2,1} = 'Single / Dual';
    anovatab{3,1} = 'MOT / VWM';

    % Planned comparisons
    stats.comparisons(1, :) = {'t test', 't', 'df', 'sd', 'p'};
    [~,p,~,t_stats] = ttest(m(1,1:n),m(3,1:n));
    stats.comparisons(2, :) = {'Single MOT vs. VWM', t_stats.tstat, t_stats.df, t_stats.sd, p};
    [~,p,~,t_stats] = ttest(m(2,1:n),m(4,1:n));
    stats.comparisons(3, :) = {'Dual MOT vs. VWM', t_stats.tstat, t_stats.df, t_stats.sd, p};
    [~,p,~,t_stats] = ttest(m(1,1:n),m(2,1:n));
    stats.comparisons(4, :) = {'MOT Single vs. Dual', t_stats.tstat, t_stats.df, t_stats.sd, p};
    [~,p,~,t_stats] = ttest(m(3,1:n),m(4,1:n));
    stats.comparisons(5, :) = {'VWM Single vs. Dual', t_stats.tstat, t_stats.df, t_stats.sd, p};

    stats.name = 'Group';
end

function stats = calcStats(results, sessions)
    if isempty(sessions)
        sessions = 1:max(unique(results.session));
    end
    idx = zeros(size(results.session));
    for j = sessions
        idx = idx | results.session==j;
    end
    results = results(idx, :);
    conditions = [strcmp(results.condition, 'MOT')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'MOT')==1, ...
                  strcmp(results.condition, 'VWM')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'VWM')==1];              
    
    for i = 1:4
        correct = results(conditions(:, i), {'correct'});

        stats.sample_size(i) = size(correct, 1);
        stats.avg(i) = mean(correct{:,:});
        [stats.ci(i,1) stats.ci(i,2)] = calcCI(stats.avg(i), stats.sample_size(i));
    end
    % Planned comparisons
    
    task_flags = strcmp(results.response_type, 'MOT'); % MOT = 1; VWM = 0
    load_flags = ~strcmp(results.condition, 'Both'); % Dual = 0; Single = 1
    X = [task_flags load_flags task_flags.*load_flags];
    [~,~,glmstats] = glmfit(X, results.correct, 'binomial');
    glmfit_table(1, :) = {'Logistic regression', 'B', 'df', 't', 'p'};
    glmfit_table(2, :) = {'Single MOT vs. VWM', glmstats.beta(2), glmstats.dfe, glmstats.t(2), glmstats.p(2)};
    
    task_flags = strcmp(results.response_type, 'MOT'); % MOT = 1; VWM = 0
    load_flags = strcmp(results.condition, 'Both'); % Dual = 1; Single = 0
    X = [task_flags load_flags task_flags.*load_flags];
    [~,~,glmstats] = glmfit(X, results.correct, 'binomial');
    glmfit_table(3, :) = {'Dual MOT vs. VWM', glmstats.beta(2), glmstats.dfe, glmstats.t(2), glmstats.p(2)};
    glmfit_table(4, :) = {'MOT Single vs. Dual', glmstats.beta(3), glmstats.dfe, glmstats.t(3), glmstats.p(3)};
    
    task_flags = strcmp(results.response_type, 'VWM'); % MOT = 0; VWM = 1
    load_flags = strcmp(results.condition, 'Both'); % Dual = 1; Single = 0
    X = [task_flags load_flags task_flags.*load_flags];
    [~,~,glmstats] = glmfit(X, results.correct, 'binomial');
    glmfit_table(5, :) = {'VWM Single vs. Dual', glmstats.beta(3), glmstats.dfe, glmstats.t(3), glmstats.p(3)};

    stats.comparisons = glmfit_table;
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

function graph_all(stats, subject_names)
    nC = size(stats(1).avg, 2);
    x = repmat(1:size(subject_names, 2), nC,1);
    m = reshape([stats.avg], nC, size(stats, 2));
    ci = reshape([stats.ci], size(x, 1), 2, size(x, 2));
    err(:, :, 1) = reshape(ci(:,1,:), size(x, 1), size(x, 2), 1) - m;
    err(:, :, 2) = m - reshape(ci(:,2,:), size(x, 1), size(x, 2), 1);
    
    % Draw bars
    figure('Color','white');
    bar(x', m');
    set(gca,'FontName','Times New Roman');
    set(gca,'FontSize',12);
    set(gca,'Color','white');
    box off;
    hold all;
    
    hL = legend(gca,{'MOT-Only','MOT-Dual', 'VWM-Only','VWM-Dual'}, 'Location', 'NorthEast');     
    set(hL, 'position', [0.77 0.8 0.1 0.1]);
    xlabel('Observers');
    ylabel('Mean accuracy (proportion correct)');
    set(gca,'XTickLabel', subject_names);
    set(gca,'YLim', [0 1]);
    
    % Draw error bars & set bar colours
    colours = [1 0 0; 0 1 0; 0 0 1; 1 1 0; 0 0 0];
    pos = [-0.275 -0.086 0.086 0.275];
    ch = get(gca, 'Children');
    for i = 1:nC
        h = errorbar(gca, x(i,:)+pos(i), m(i,:), err(i,:,1), err(i,:,2));
        set(h,'linestyle','none');
        set(h, 'Color', colours(5,:));
        set(ch(2), 'FaceColor', colours(i,:));
    end
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
    for i = 1:4
        h = errorbar(gca, x(:,i), y(:,i), err(i,2), err(i,1));
        set(h,'linestyle','none');
        set(h, 'Color', 'b');
    end
end