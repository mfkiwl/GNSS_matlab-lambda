function [dtropo] = tropo(Z,h)
pr = 1013.25;
Tr = 18 + 273.15;
Hr = 50;
H = Hr * exp(-0.0006396*h);
T = Tr - 0.0065*h;
p = pr*(1-0.0000226*h)^5.225;
e = (H/100)*exp(-37.2465+0.213166*T - 0.000256908*T^2);
dtropo = (0.002277/cos((90-Z)*pi/180))*(p+(1255/T + 0.05)*e);
end
