% Calculate mean number of objects tracked (as per Cowan 2001, cited in Fougnie & Marois 2006)
function k = CowanK(n, hr, cr)
    k = (hr + cr - 1)*n;
end
