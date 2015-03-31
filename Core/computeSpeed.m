function [speed q] = computeSpeed(correct, speed, pThreshold)
    if nargin < 2
        pThreshold = 0.75;
    end
    %staircaseResults = squeeze(staircaseResults(1,:,:));
    % Initialize Quest
    tGuess = mean(speed); tGuessSd = 15; beta=3.5; delta=0.05; gamma=0.0143;
    q=QuestCreate(-log10(tGuess),log10(tGuessSd),pThreshold,beta,delta,gamma);
    q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
    for j=1:length(speed)
        q = QuestUpdate(q,-log10(speed(j)),correct(j));
    end
    betaEstimate = QuestBetaAnalysis(q);
    q.beta = betaEstimate;
    q = QuestRecompute(q);
    speed = 10^(-QuestMean(q));
end