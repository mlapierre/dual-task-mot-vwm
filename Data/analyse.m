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
        else
            fprintf('%s results table does not contain valid session information. Skipped.\n', subject_names{i});
            stats(i) = struct('correct',[], 'sample_size', [], 'avg', [], 'ci', []);
        end
    end
    
    if size(subject_names, 2) > 1
        % Remove empty results sets
        graph_stats = stats;
        idx = arrayfun(@(x)(isempty(x.avg)), stats);
        graph_stats(idx) = [];
        graph_subject_names = subject_names;
        graph_subject_names(idx) = [];

        graph_stats(size(graph_stats, 2) + 1) = calcGroupStats(graph_stats);
        graph_subject_names{size(graph_subject_names, 2) + 1} = 'Group';
        %graph_all(graph_stats, graph_subject_names);
        
        fprintf('\nTwo-way ANOVA Task (MOT / VWM) by Load (Single / Dual)\n');
        nC = size(graph_stats(1).avg, 2);
        n = size(graph_stats, 2) - 1;
        x = repmat(1:size(graph_subject_names, 2), nC, 1);
        m = reshape([graph_stats.avg], nC, size(graph_stats, 2));
        ci = reshape([graph_stats.ci], size(x, 1), 2, size(x, 2));
        X = [m(1,1:n) m(3,1:n); m(2,1:n) m(4,1:n)]';
        [p,anovatab,anova_stats] = anova2(X, n, 'off');
        anovatab{2,1} = 'Single / Dual';
        anovatab{3,1} = 'MOT / VWM';
        anovatab
        
        fprintf('Group data, MOT, Single vs. Dual');
        [~,p,~,anova_stats] = ttest(m(1,1:n),m(2,1:n))
        fprintf('Group data, VWM, Single vs. Dual');
        [~,p,~,anova_stats] = ttest(m(3,1:n),m(4,1:n))
        
        
    else
        graph_session(stats(1), subject_names{1});
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

function stats = calcGroupStats(graph_stats)
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
    stats.correct = [];
    stats.sample_size = n;
    stats.avg = m(:, n + 1)';
    stats.ci = [m(:, n + 1)-sem*1.96 m(:, n + 1)+sem*1.96];
end

function stats = calcStats(results, sessions)
    conditions = [strcmp(results.condition, 'MOT')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'MOT')==1, ...
                  strcmp(results.condition, 'VWM')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'VWM')==1];              
    for i = 1:4
        if isempty(sessions)
            correct = results(conditions(:, i), {'correct'});
        else
            idx = zeros(size(results.session));
            for j = sessions
                idx = idx | results.session==j & conditions(:, i);
            end
            correct = results(idx, {'correct'});
        end
        stats.correct{i} = correct;
        stats.sample_size(i) = size(correct, 1);
        stats.avg(i) = mean(correct{:,:});
        [stats.ci(i,1) stats.ci(i,2)] = calcCI(stats.avg(i), stats.sample_size(i));
    end
    
    fprintf('glmfit Task (MOT / VWM) by Load (single / dual)\n');
    fprintf('Single task: ');
    task_flags = strcmp(results.response_type, 'MOT'); % MOT = 1; VWM = 0
    load_flags = ~strcmp(results.condition, 'Both'); % Dual = 0; Single = 1
    X = [task_flags load_flags task_flags.*load_flags];
    [~,~,glmstats] = glmfit(X, results.correct, 'binomial');
    if glmstats.p(2) < 0.05
        if glmstats.beta(2) > 0
            difference = 'MOT < VWM';
        else
            difference = 'MOT < VWM';
        end
    else
        difference = 'MOT = VWM';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',...
        difference,glmstats.beta(2),glmstats.dfe,glmstats.t(2),glmstats.p(2));
    
    task_flags = strcmp(results.response_type, 'MOT'); % MOT = 1; VWM = 0
    load_flags = strcmp(results.condition, 'Both'); % Dual = 1; Single = 0
    X = [task_flags load_flags task_flags.*load_flags];
    [~,~,glmstats] = glmfit(X, results.correct, 'binomial');
    fprintf('Dual task: ');
    if glmstats.p(2) < 0.05
        if glmstats.beta(2) > 0
            difference = 'MOT < VWM';
        else
            difference = 'MOT < VWM';
        end
    else
        difference = 'MOT = VWM';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',...
        difference,glmstats.beta(2),glmstats.dfe,glmstats.t(2),glmstats.p(2));
    
    fprintf('MOT: ');
    if glmstats.p(3) < 0.05
        if glmstats.beta(3) > 0
            difference = 'Single > Dual';
        else
            difference = 'Single > Dual';
        end
    else
        difference = 'Single = Dual';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',...
        difference,glmstats.beta(3),glmstats.dfe,glmstats.t(3),glmstats.p(3));
    
    task_flags = strcmp(results.response_type, 'VWM'); % MOT = 0; VWM = 1
    load_flags = strcmp(results.condition, 'Both'); % Dual = 1; Single = 0
    X = [task_flags load_flags task_flags.*load_flags];
    [~,~,glmstats] = glmfit(X, results.correct, 'binomial');
    fprintf('VWM: ');
    if glmstats.p(3) < 0.05
        if glmstats.beta(3) > 0
            difference = 'Single > Dual';
        else
            difference = 'Single > Dual';
        end
    else
        difference = 'Single = Dual';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',...
        difference,glmstats.beta(3),glmstats.dfe,glmstats.t(3),glmstats.p(3));
    
    fprintf('\n');
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