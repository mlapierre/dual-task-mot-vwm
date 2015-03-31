function y = stmMorey(x,m)
    y = std(x)*(m/(m-1))/sqrt(length(x));
end