function [W] = getSuavidadTrayectoria(y_d, N_ignore, graficar)
% GETSUAVIDADTRAYECTORIA Función para determinar suavidad de curvas por 
% medio del cálculo de energia de de flexion de vigas delgadas de Bernoulli.
% Se realiza interpolacion de datos discretos con trazadores cúbicos para 
% formar y(x) y se calcula la primera y segunda derivada y'(x), y''(x) para 
% calcular W (bending energy). Este es un indice de que tan suave es la 
% curva. Si se posee un línea recta, la energia es W = 0.
% -------------------------------------------------------------------------
%
% Autor: Aldo Aguilar Nadalini (15170)
%
% Link: https://math.stackexchange.com/questions/1369155/how-do-i-rate-
%       smoothness-of-discretely-sampled-data-picture
%
% Inputs:
%   - Data: Vector de datos discretos a analizar. Columna 1 = Coordenadas X
%     y Columna 2 = Coordenadas Y.
%   - N_ignore: Número de datos iniciales a ignorar por inexactitud de 
%     interpolacion
%   - graficar: Booleano para graficar (1) o no (0)
%
% Outputs:
%   - W: Energía de flexión de una trayectoria
%
% -------------------------------------------------------------------------

    N = numel(y_d);                 % Cantidad de datos muestreados
    x_d = 1:1:N;                    % Datos muestreados cada segundo durante 1000 segundos

    h = 0.25;                       % Step size para generacion de puntos de interpolacion
    X = 0:h:N;                      % Vector de X para cada punto interpolado
    Y = spline(x_d,y_d,X);          % Curva Y(x) continua interpolada de y(x) discreta

    % Graficacion de marcadores y la grafica interpolada resultante
    if (graficar)
        h0 = figure;
        set(h0,'color','w');
        set(h0,'units','points','position',[60,45,1020,540]);
        plot(x_d,y_d,'o',X,Y);
        grid on; grid minor;
        legend('Datos discretos','Curva Y(x) interpolada');
    end

    % Calculo de primera y segunda derivada de Y(x) continua en cada punto
    % interpolado
    Y_p = diff(Y)/h;                 % Primera derivada Y'(x)
    Y_pp = diff(Y_p)/h;              % Segunda derivada Y''(x)

    % Graficacion de curva original con sus derivadas
    if (graficar)
        h1 = figure;
        set(h1,'color','w');
        set(h1,'units','points','position',[60,45,1020,540]);
        plot(X,Y,'b');
        hold on;
        plot(X(1:length(Y_p)),Y_p,'r');
        hold on;
        plot(X(1:length(Y_pp)),Y_pp,'k');
        hold on;
        grid on; grid minor;
        legend('Y(x)','Y´(x)','Y´´(x)');
    end

    % Calculo de energia de deflexion de Bernoulli
    x_k_1 = 0;                       % x_k-1     
    x_k = 0;                         % x_k 
    ypp_k_1 = 0;                     % y''_k-1 
    ypp_k = 0;                       % y''_k
    sum = 0;
    X = X(1:length(Y_pp));

    i = N_ignore/h;                  % Cantidad de datos interpolados a ignorar por inexactitud inicial
    for k = i:N-1
        l_k = X(k) - x_k_1;
        sum = sum + l_k*(ypp_k_1^2 + ypp_k_1*Y_pp(k) + Y_pp(k)^2);
        x_k_1 = X(k);
        ypp_k_1 = Y_pp(k);
    end
    W = (1/6)*sum;                   % Energia de deflexion (suavidad)

end