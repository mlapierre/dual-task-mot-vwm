clear all;
fn = {'ry1_mot_mcs_1_25-Mar-2013_MOT_VWM_3_0.0.1_Session_2.mat',...
    'ry1_mot_mcs_1_25-Mar-2013_MOT_VWM_3_0.0.1_Session_2.mat'}; 

%fn = {'as1_mot_mcs_1_25-Mar-2013_MOT_VWM_3_0.0.1_Session_2.mat',...
%    'as1_mot_mcs_1_25-Mar-2013_MOT_VWM_3_0.0.1_Session_3.mat'};

numSessions = size(fn,2);
numTrialsPerSession = 60;

load(fn{1});

for i=1:numTrialsPerSession
    speed(i) = trials(i).Speed;
end
stimLevels = unique(speed);

for i=1:numSessions
    load(fn{i});
    
    stimLevels = unique(speed);
    numTrialsPerLevel = numTrialsPerSession/size(stimLevels,2);
    for j=1:size(stimLevels,2)
        corrects((i-1)*numTrialsPerLevel+1:i*numTrialsPerLevel,j) = correct(speed == stimLevels(j));
        speeds((i-1)*numTrialsPerLevel+1:i*numTrialsPerLevel,j) = repmat(stimLevels(j),1,numTrialsPerLevel);
    end
end

chance = 0.5;
threshold = 0.7;
neg = 1;

res.intensity = reshape(speeds,1,numTrialsPerSession*numSessions);
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
