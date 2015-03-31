function linePerBinPerCond(numBins, binSize, xVals, ylim, titleStr, legendStr, legendLoc)
for j = 1:numBins
    y(j,:) = mean(xVals((j-1)*binSize+1:j*binSize,:));
    err(j,:) = stm(xVals((j-1)*binSize+1:j*binSize,:))*1.96;
end

x = 1:numBins;

plot(x-0.1, y(:,1), 'b+-',x, y(:,2),'go:',x+0.1, y(:,3)','r*-.');
if ~isempty(titleStr)
    title(titleStr);
end
if nargin < 7
    legendLoc = [];
end
if ~isempty(legendStr)
    if ~isempty(legendLoc)
        legend(legendStr, 'Location', legendLoc);
    else
        legend(legendStr);
    end
end
hold all;
set(gca, 'YLim', ylim);       
h = errorbar(gca,x-0.1,y(:,1), err(:,1));
set(h,'linestyle','none');
set(h, 'Color', 'b');
h = errorbar(gca,x,y(:,2), err(:,2));
set(h,'linestyle','none');
set(h, 'Color', 'g');
h = errorbar(gca,x+0.1,y(:,3), err(:,3));
set(h,'linestyle','none');
set(h, 'Color', 'r');
end