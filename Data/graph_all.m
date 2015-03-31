% display all observers' performance in one graph
clear all;
obs = {'AS','ML','RY','ZT','SS','Group'};
%              MOT           VWM      
%         Single  Dual  Single  Dual
acc(:,1)=[0.8242 0.6484 0.7930 0.6211];
err(:,1)=[0.0467 0.0586 0.0497 0.0595];
acc(:,2)=[0.7734 0.6758 0.8047 0.6680];
err(:,2)=[0.0514 0.0575 0.0487 0.0578];
acc(:,3)=[0.7461 0.6367 0.8086 0.6992];
err(:,3)=[0.0534 0.0590 0.0483 0.0563];
acc(:,4)=[0.8398 0.7227 0.8984 0.7383];
err(:,4)=[0.0450 0.0549 0.0371 0.0540];
acc(:,5)=[0.7539 0.6641 0.8438 0.6406];
err(:,5)=[0.0529 0.0580 0.0446 0.0589];

% Group
acc(:,size(obs,2)) = mean(acc(:,1:size(obs,2)-1),2);
m = 4;
n = size(acc(:,1:size(obs,2)-1),2);
norm = (acc(:,1:size(obs,2)-1) - repmat(mean(acc(:,1:size(obs,2)-1)),m,1)) + mean(mean(acc(:,1:size(obs,2)-1)));
v = sqrt(std(norm,0,2));
sd = v.^2 *(m/(m-1));
sem = sd/sqrt(n);
err(:,size(obs,2)) = sem*1.96;

%%
% fprintf('\nanova_rm([S O N])\n');
% observer_means = acc(:,1:size(obs,2))';
% [~,anovatab] = anova_rm(observer_means, 'off')
% disp('ttest2(S, N)');
% [h,p,ci,stats] = ttest(observer_means(:,1), observer_means(:,3))
% disp('ttest2(O, N)');
% [h,p,ci,stats] = ttest(observer_means(:,2), observer_means(:,3))
% disp('ttest2(S, O)');
% [h,p,ci,stats] = ttest(observer_means(:,1), observer_means(:,2))
fprintf('\nanova2(MOT / VWM by Single / Dual)\n');
reps = 5;
X = [acc(1,1:5)' acc(3,1:5)'; acc(2,1:5)' acc(4,1:5)'];
[p,anovatab,stats] = anova2(X, reps, 'off')

[~,p,~,stats]=ttest(acc(1,:),acc(2,:))
[~,p,~,stats]=ttest(acc(3,:),acc(4,:))

%% 
figure('Color','white');
set(gcf, 'Position', [50 50 700 350])
x = repmat(1:size(obs,2),4,1)';
y = acc';
%bar(x,y,'LineWidth',1.2);
bar(x,y);
set(gca,'FontName','Times New Roman');
set(gca,'FontSize',12);
%set(gca,'FontWeight','Bold');
set(gca,'Color','white');
box off;
hold all;
hL = legend(gca,{'MOT-Only','MOT-Dual', 'VWM-Only','VWM-Dual'}, 'Location', 'NorthEast');     
set(hL, 'position', [0.77 0.8 0.1 0.1]);
xlabel('Observers');
ylabel('Mean accuracy (proportion correct)');
set(gca,'XTickLabel', obs);
set(gca,'YLim', [0.5 1]);
colours = [1 0 0; 0 1 0; 0 0 1; 0 0 0; 1 1 0];
ch = get(gca, 'Children');
h = errorbar(gca,x(:,1)-0.275,y(:,1), err(1,:));
set(h,'linestyle','none');
%set(h,'LineWidth',1);
set(h, 'Color', colours(4,:));
set(ch(2), 'FaceColor', colours(3,:));
h = errorbar(gca,x(:,2)-.086,y(:,2), err(2,:));
set(h,'linestyle','none');
%set(h,'LineWidth',1);
set(h, 'Color', colours(4,:));
set(ch(1), 'FaceColor', colours(1,:));    
h = errorbar(gca,x(:,3)+0.086,y(:,3), err(3,:));
set(h,'linestyle','none');
%set(h,'LineWidth',1);
set(h, 'Color', colours(4,:));
set(ch(2), 'FaceColor', colours(2,:));    
h = errorbar(gca,x(:,4)+0.275,y(:,4), err(4,:));
set(h,'linestyle','none');
%set(h,'LineWidth',1);
set(h, 'Color', colours(4,:));
set(ch(2), 'FaceColor', colours(2,:));    
%imwrite(applyhatch_pluscolor(gcf,'-/-/',1,[],[],[],1,1),'test.png','png');
[im_hatch,~] = applyhatch_pluscolor(gcf,'\|/+.-',1,[],[],300,1.5,1);
imwrite(im_hatch,'fig14b.tif','tiff','Resolution',300,'Compression','lzw');
