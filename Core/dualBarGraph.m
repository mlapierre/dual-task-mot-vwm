function dualBarGraph(name, xVals, yLim)
    figure('Name',name);
    
    subplot(1,2,1);
    x = [1 2 3];
    y = [mean(xVals(:,1)) mean(xVals(:,2)) mean(xVals(:,3))];
    err = [stm(xVals(:,1))*1.96 stm(xVals(:,2))*1.96 stm(xVals(:,3))*1.96];
    bar(x,y);
    hold all;
    h = errorbar(x,y,err, 'r');
    set(h,'linestyle','none');
    set(gca,'XTickLabel',{'S', 'M', 'V'});
    set(gca,'YLim', yLim);
    title('MOT');

    subplot(1,2,2);
    y = [mean(xVals(:,4)) mean(xVals(:,5)) mean(xVals(:,6))];
    err = [stm(xVals(:,4))*1.96 stm(xVals(:,5))*1.96 stm(xVals(:,6))*1.96];    
    bar(x,y);
    hold all;
    h = errorbar(x,y,err, 'r');
    set(h,'linestyle','none');
    set(gca,'XTickLabel',{'S', 'M', 'V'});
    set(gca,'YLim', yLim);
    title('VWM');
end