classdef Session
    properties
        Win
        Config
        TestResults
        PracticeResults
        QuestResults
        SessionStartTime
        SessionEndTime
    end % properties
    
    methods
        function obj = Session(conf, window)
            obj.Win = window;
            obj.Config = conf;
        end

        function stim = GetStim(obj, taskType, stimAll, j)
            if taskType == TaskType.MOT
                stim = stimAll(j);
            else
                stim = stimAll(((j-1)*obj.Config.NumUniqueStimPerTrial)+1:((j-1)*obj.Config.NumUniqueStimPerTrial)+obj.Config.NumUniqueStimPerTrial);
            end
        end
        
        function SaveResults(obj, results)
            if exist(obj.Config.ResultsFN, 'file')
                save(obj.Config.ResultsFN, '-APPEND', 'results');
            else
                save(obj.Config.ResultsFN, 'results');
            end
        end
        
        function SaveSession(obj)
            if exist(obj.Config.SessionFN, 'file')
                save(obj.Config.SessionFN, '-APPEND', 'obj');
            else
                save(obj.Config.SessionFN, 'obj');
            end
        end
        
        function [speed q] = CalcThreshold(obj, testedSpeed, correct, pThreshold, gamma)
            if nargin < 4
                gamma = 0.5;
            end
            if nargin < 3
                pThreshold = 0.75;
            end
            % Initialize Quest
            tGuess = mean(testedSpeed); tGuessSd = 15; beta=3.5; delta=0.05;
            q=QuestCreate(-log10(tGuess),log10(tGuessSd),pThreshold,beta,delta,gamma);
            q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
            for j=1:length(testedSpeed)
                q = QuestUpdate(q,-log10(testedSpeed(1,j)),correct(1,j));
            end
            betaEstimate = QuestBetaAnalysis(q);
            q.beta = betaEstimate;
            q = QuestRecompute(q);
            speed = 10^(-QuestMean(q));
            disp(speed);
        end
    end
end
