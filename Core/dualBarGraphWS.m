function dualBarGraphWS(name, xVals, yLim)
    figure('Name',name);
    
    gaA = mean(mean(xVals(:,1:3)));
    gaB = mean(mean(xVals(:,4:6)));
    nxA = xVals(:,1:3) - repmat((mean(xVals(:,1:3),2) + gaA),1,3);
    nxB = xVals(:,4:6) - repmat((mean(xVals(:,4:6),2) + gaB),1,3);
    
    subplot(1,2,1);
    x = [1 2 3];
    y = [mean(xVals(:,1)) mean(xVals(:,2)) mean(xVals(:,3))];
    err = [stm(nxA(:,1))*1.96 stm(nxA(:,2))*1.96 stm(nxA(:,3))*1.96];
    bar(x,y);
    hold all;
    h = errorbar(x,y,err, 'r');
    set(h,'linestyle','none');
    set(gca,'XTickLabel',{'S', 'M', 'V'});
    set(gca,'YLim', yLim);
    title('MOT');

    subplot(1,2,2);
    y = [mean(xVals(:,4)) mean(xVals(:,5)) mean(xVals(:,6))];
    err = [stm(nxB(:,1))*1.96 stm(nxB(:,2))*1.96 stm(nxB(:,3))*1.96];
    bar(x,y);
    hold all;
    h = errorbar(x,y,err, 'r');
    set(h,'linestyle','none');
    set(gca,'XTickLabel',{'S', 'M', 'V'});
    set(gca,'YLim', yLim);
    title('VWM');
end