function [MOT, VWM, conditions] = getCorrectByCondition(results, blocks, trials)
    for i = 1:blocks
        if find(any(results(i,1).Condition == Condition.PerformVWM))
            conditions{i} = 'VWM-Only';
        elseif find(any(results(i,1).Condition == Condition.PerformMOT))
            conditions{i} = 'MOT-Only';
        elseif find(any(results(i,1).Condition == Condition.PerformBoth))
            conditions{i} = 'Both';
        else
            error('Invalid Condition');
        end
        
        if ~isempty([results(i,:).MOTNumCorrect])
            MOT.Correct(:,i) = [results(i,:).MOTNumCorrect];
            %MOTMeansPerSession(sess, i) = mean(squeeze(MOTCorrect(sess, i, :)));
            %MOTSDPerSession(sess, i) = std(squeeze(MOTCorrect(sess, i, :)));
            %MOTHit(sess, i, :) = [results(i,:).MOTNumCorrect]' & [results(i,:).MOTValidProbe]';
            %MOTHit(sess, i, find(~[results(i,:).MOTValidProbe]')) = [];
            MOT.ValidProbe(:,i) = [results(i,:).MOTValidProbe];
            %MOTCR(sess, i,:) = [results(i,:).MOTNumCorrect]' & ~[results(i,:).MOTValidProbe]';
        else
            MOT.Correct(:,i) = zeros(trials,1);
            MOT.ValidProbe(:,i) = zeros(trials,1);
        end
        if ~isempty([results(i,:).VWMCorrect])
            VWM.Correct(:,i) = [results(i,:).VWMCorrect];
            %VWMMeansPerSession(sess, i) = mean(squeeze(VWMCorrect(sess, i, :)));
            %VWMSDPerSession(sess, i) = std(squeeze(VWMCorrect(sess, i, :)));
            %VWMHit(sess, i, :) = [results(i,:).VWMCorrect]' & [results(i,:).VWMValidProbe]';
            %VWMCR(sess, i, :) = [results(i,:).VWMCorrect]' & ~[results(i,:).VWMValidProbe]';
            VWM.ValidProbe(:,i) = [results(i,:).VWMValidProbe];
        else
            VWM.Correct(:,i) = zeros(trials,1);
            VWM.ValidProbe(:,i) = zeros(trials,1);
        end
    end
end