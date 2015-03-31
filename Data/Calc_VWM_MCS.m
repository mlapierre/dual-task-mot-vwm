clear all;
fn = {'as1_vwm_mcs_1_25-Mar-2013_MOT_VWM_3_0.0.1_Session_1.mat'};%,...
%fn = {'ry1_vwm_mcs_1_25-Mar-2013_MOT_VWM_3_0.0.1_Session_1_Results.mat'};%,...
    %'zst1_vwm_mcs_1_14-Mar-2013_MOT_VWM_3_0.0.1_Session_2.mat'}; 

numSessions = size(fn,2);
numTrialsPerSession = 60;

load(fn{1});

%for i=1:numTrialsPerSession
%    speed(i) = trials(i).Speed;
%end
stimLevels = unique(vwm_objects);

for i=1:numSessions
    load(fn{i});
    
    stimLevels = unique(vwm_objects);
    numTrialsPerLevel = numTrialsPerSession/size(stimLevels,2);
    for j=1:size(stimLevels,2)
        corrects((i-1)*numTrialsPerLevel+1:i*numTrialsPerLevel,j) = correct(vwm_objects == stimLevels(j));
        objects((i-1)*numTrialsPerLevel+1:i*numTrialsPerLevel,j) = repmat(stimLevels(j),1,numTrialsPerLevel);
    end
end

chance = 0.5;
threshold = 0.7;
neg = 1;

res.intensity = reshape(objects,1,numTrialsPerSession*numSessions);
res.response = reshape(corrects,1,numTrialsPerSession*numSessions);

%res.response(res.intensity==22) = [];
%res.intensity(res.intensity==22) = [];
%res.response(res.intensity==30) = [];
%res.intensity(res.intensity==30) = [];

%[s q] = CalcThreshold(res.intensity, res.response, threshold, chance, neg)
figure;
plotPsycho(res,'Speed');

%x = exp(linspace(log(min(res.intensity)),log(max(res.intensity)),101));
%p.t = s; p.b = q.beta; y = fliplr(Weibull(p,x));
%hold on; plot(log(x),y*100,'r-');
