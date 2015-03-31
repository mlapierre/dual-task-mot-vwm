function correct_by_condition = Calc_And_Show_Results(fn)
    max_sessions = size(fn,1);
    max_trials = 16;
    num_conditions = 4;
    condition_names = {'MOT-Only','VWM-Only','MOT-dual','VWM-dual'};

    correct = NaN(max_trials, num_conditions, max_sessions);
    conditions = NaN(max_trials, num_conditions, max_sessions);
    TrialTime = NaN(max_sessions,1);

    num_sessions = 1;
    for sess = 1:max_sessions
        if ~isempty(fn{sess})
            num_sessions = sess;
            load(fn{sess});
            TrialTime(sess) = (endTime-startTime)/60;
            sess_cond=[obj.TestResults.Condition];
            sess_correct=[obj.TestResults.Correct];
            sess_task_type = [obj.TestResults.TaskType];
            correct(:, 1, sess) = sess_correct(sess_cond==Condition.PerformMOT);
            correct(:, 2, sess) = sess_correct(sess_cond==Condition.PerformVWM);
            correct(:, 3, sess) = sess_correct(sess_cond==Condition.PerformBoth & sess_task_type==TaskType.MOT);
            correct(:, 4, sess) = sess_correct(sess_cond==Condition.PerformBoth & sess_task_type==TaskType.VWM);
        end
    end
    fprintf('Total time: %.2f (hours)\nAverage time: %.2f (mins)\n',sum(TrialTime(1:num_sessions))/60, mean(TrialTime(1:num_sessions)));
    fprintf('Sessions: %d\ntrials per condition per session: %d\ntotal trials per condition: %d\ntotal trials per session: %d\ntotal trials: %d\n',...
        max_sessions, max_trials, num_sessions*max_trials, max_trials*num_conditions, max_trials*num_conditions*num_sessions);
    means = mean(correct); 
    errs = means.*(1-means)./4;
    
    means_by_condition = mean(means(:,:,1:num_sessions),3);
    errs_by_condition = mean(errs(:,:,1:num_sessions),3);
    
    
    correct_by_condition(:,1) = reshape(correct(:,1,1:num_sessions), num_sessions*max_trials, 1);
    correct_by_condition(:,2) = reshape(correct(:,2,1:num_sessions), num_sessions*max_trials, 1);
    correct_by_condition(:,3) = reshape(correct(:,3,1:num_sessions), num_sessions*max_trials, 1);
    correct_by_condition(:,4) = reshape(correct(:,4,1:num_sessions), num_sessions*max_trials, 1);
    
    for i = 1:size(condition_names,2)
        m(i) = mean(correct_by_condition(1:num_sessions*max_trials,i));
        e(i) = stm(correct_by_condition(1:num_sessions*max_trials,i))*1.96;
        fprintf('%s: %.3f (%.3f)\n', condition_names{i}, m(i), e(i));
    end
    fprintf('acc(:,)=[%1.4f %1.4f %1.4f %1.4f];\n',m(1),m(3),m(2),m(4));
    fprintf('err(:,)=[%1.4f %1.4f %1.4f %1.4f];\n',e(1),e(3),e(2),e(4));
    %[h,p] = ttest2(correct_by_condition(:,1), correct_by_condition(:,3)) % mot-only vs. mot-dual
    %[h,p] = ttest2(correct_by_condition(:,2), correct_by_condition(:,4)) % vwm-only vs. vwm-dual
    fprintf('glmfit task (MOT / VWM) by condition (single / dual) by interaction on accuracy (hit/miss)\n');
    %task_flags = reshape(ones(num_sessions*max_trials, 1)*[Condition.MOT Condition.VWM Condition.MOT Condition.VWM],num_sessions*max_trials*num_conditions,1);
    %condition_flags = reshape(ones(num_sessions*max_trials, 1)*[Condition.Single Condition.Single Condition.Dual Condition.Dual],num_sessions*max_trials*num_conditions,1);
    task_flags = reshape(ones(num_sessions*max_trials, 1)*[0 1 0 1],num_sessions*max_trials*num_conditions,1);
    condition_flags = reshape(ones(num_sessions*max_trials, 1)*[0 0 1 1],num_sessions*max_trials*num_conditions,1);
    y = reshape(correct_by_condition, num_sessions*max_trials*num_conditions, 1);
    X = [task_flags condition_flags task_flags.*condition_flags];
    [~,~,stats] = glmfit(X, y, 'binomial');
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n','Interaction',stats.beta(4),stats.dfe,stats.t(4),stats.p(4));
    %fprintf('MOT = 0, Single = 0');
    fprintf('When single task\n');
    if stats.p(2) < 0.05
        if stats.beta(2) > 0
            difference = 'MOT < VWM';
        else
            difference = 'MOT < VWM';
        end
    else
        difference = 'MOT = VWM';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',difference,stats.beta(2),stats.dfe,stats.t(2),stats.p(2));
    
    task_flags = reshape(ones(num_sessions*max_trials, 1)*[0 1 0 1],num_sessions*max_trials*num_conditions,1);
    condition_flags = reshape(ones(num_sessions*max_trials, 1)*[1 1 0 0],num_sessions*max_trials*num_conditions,1);
    y = reshape(correct_by_condition, num_sessions*max_trials*num_conditions, 1);
    X = [task_flags condition_flags task_flags.*condition_flags];
    [~,~,stats] = glmfit(X, y, 'binomial');
    %fprintf('MOT = 0, Single = 1');
    fprintf('When dual task\n');
    if stats.p(2) < 0.05
        if stats.beta(2) > 0
            difference = 'MOT < VWM';
        else
            difference = 'MOT < VWM';
        end
    else
        difference = 'MOT = VWM';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',difference,stats.beta(2),stats.dfe,stats.t(2),stats.p(2));
    
    fprintf('For MOT\n');
    if stats.p(3) < 0.05
        if stats.beta(3) > 0
            difference = 'Single > Dual';
        else
            difference = 'Single > Dual';
        end
    else
        difference = 'Single = Dual';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',difference,stats.beta(3),stats.dfe,stats.t(3),stats.p(3));

    task_flags = reshape(ones(num_sessions*max_trials, 1)*[1 0 1 0],num_sessions*max_trials*num_conditions,1);
    condition_flags = reshape(ones(num_sessions*max_trials, 1)*[1 1 0 0],num_sessions*max_trials*num_conditions,1);
    y = reshape(correct_by_condition, num_sessions*max_trials*num_conditions, 1);
    X = [task_flags condition_flags task_flags.*condition_flags];
    [~,~,stats] = glmfit(X, y, 'binomial');
    %fprintf('MOT = 1, Single = 1');
    fprintf('For VWM\n');
    if stats.p(3) < 0.05
        if stats.beta(3) > 0
            difference = 'Single > Dual';
        else
            difference = 'Single > Dual';
        end
    else
        difference = 'Single = Dual';
    end
    fprintf('%s | B=%.3f, t(%d)=%.3f, p=%.3f\n',difference,stats.beta(3),stats.dfe,stats.t(3),stats.p(3));

%     if num_sessions > 1
%         figure;
%         title('Percent correct by condition by session');
%         x = repmat(1:num_sessions,size(condition_names,1),1)';
%         means = squeeze(means(:,:,1:num_sessions))';
%         errs = squeeze(errs(:,:,1:num_sessions))';
%         bar(x,means);
%         hold all;
%         ax1 = gca;
%         legend(ax1,condition_names, 'Location', 'NorthEast'); 
%         set(ax1, 'YLim', [0 1]);       
%         ylimits = get(ax1,'YLim');
%         yinc = (ylimits(2)-ylimits(1))/5;
%         set(ax1, 'YTick',[ylimits(1):yinc:ylimits(2)]);
%         set(ax1, 'XTick',x(:,1));
%     end
%     colours = [1 0 0; 0 1 0; 0 0 1; 0 0 0];
%     ch = get(ax1, 'Children');
%     h = errorbar(ax1,x(:,1)-0.13,means(:,1), errs(:,1));
%     set(h,'linestyle','none');
%     set(h, 'Color', colours(1,:));
%     set(ch(2), 'FaceColor', colours(1,:));
%     h = errorbar(ax1,x(:,2)+0.13,means(:,2), errs(:,2));
%     set(h,'linestyle','none');
%     set(h, 'Color', colours(3,:));
%     set(ch(1), 'FaceColor', colours(3,:));   
    
%     figure;
%     title('Percent correct by condition');
%      x = 1:num_conditions;
%     bar(x,means_by_condition);
%     hold all;
%     set(gca, 'YLim', [0.5 1]);       
%     set(gca,'XTickLabel',condition_names);
%     h = errorbar(gca,x,means_by_condition, errs_by_condition);
%     set(h,'linestyle','none');
%     set(h, 'Color', [0 0 0]);
end