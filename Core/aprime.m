function a = aprime(h, f)
    a = 0.5 + (abs(h-f)/(h-f)).*((h-f).^2+abs(h-f))./(4*max([h; f])-(4*h.*f));
end