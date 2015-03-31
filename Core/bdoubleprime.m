function b = bdoubleprime(h, f)
    b = (abs(h-f)/(h-f)).*((h.*(1-h)-f.*(1-f))./(h.*(1-h)+f.*(1-f)));
end