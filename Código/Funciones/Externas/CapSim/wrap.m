function d = wrap(x)
Z  = (x>pi).*(x-2*pi)+(x<-pi).*(x+2*pi);
d  = Z+x.*~Z;

% d = mod(x+pi,2*pi)-pi;