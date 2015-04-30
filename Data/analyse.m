function analyse(subject_name)
    data_fn = ['data' filesep subject_name '.mat'];
    if ~exist(data_fn, 'file')
        error('Could not find %s\n', data_fn);
    end
    load(data_fn, 'results');
    fprintf('Data loaded from %s\n', data_fn);

    conditions = [strcmp(results.condition, 'MOT')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'MOT')==1, ...
                  strcmp(results.condition, 'VWM')==1, ...
                  strcmp(results.condition, 'Both')==1 & strcmp(results.response_type, 'VWM')==1];              
    for i = 1:4
        %t = results(results.session==1 & conditions(:, i), {'correct'});
        t = results(conditions(:, i), {'correct'});
        avg(i) = mean(t{:,:});
        [ci(i,1) ci(i,2)] = calcCI(avg(i), size(t, 1));
    end
    graph_session(avg, ci, subject_name);
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

function graph_session(m, ci, subject_name)
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