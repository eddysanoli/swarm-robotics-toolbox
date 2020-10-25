function [VelLineal, VelAngular] = getControllerOutput(ControllerType, Meta, PuckPosicion_Actual, PuckOrientacion_Actual, RadioPuck)
% GETCONTROLLEROUTPUT Función que retorna la velocidad lineal y angular de
% los E-Pucks de acuerdo al controlador deseado. 
% -------------------------------------------------------------------------
% Inputs:
%   - ControllerType: Tipo de controlador que se desea acoplar al E-Puck.
%     Según el tipo de controlador se pueden llegar a requerir inputs
%     adicionales.
%   - Meta: Matriz de 1x2. Punto que desea alcanzar actualmente el E-Puck. 
%   - PuckPosicion_Actual: Matriz de Nx2. Cuenta con la misma estructura
%     que en el caso de "PartPosicion_Actual" con la diferencia que N ahora
%     simboliza el número de robots.
%   - PuckOrientacion_Actual: Vector columna con N ángulos en radianes, uno
%     por cada E-Puck. Este consiste del ángulo que existe entre el eje X+
%     del plano y la línea de orientación de los pucks si nos desplazamos
%     en contra de las manecillas del reloj. 
%   - RadioPuck: Radio de isomorfismo de E-Puck (Si eso sonó a chino: Es
%     un ajuste que se hace porque no se puede suponer que el centro del
%     robot está en el centro como tal. Se supone que está adelante de él,
%     comúnmente en el radio del mismo). 
%
% Outputs:
%   - VelLineal: Vector columna con tantas filas como Pucks. Velocidad en
%     la dirección de la línea de orientación del Puck.
%   - VelAngular: Vector columna con tantas filas como Pucks. Velocidad
%     angular o tasa a la que cambia el ángulo de la línea de orientación
%     del Puck.
% -------------------------------------------------------------------------
%
% Opciones "ControllerType"
%   
%   - Pose Simple: Controlador propio del libro "Introduction to Autonomous
%     Mobile Robots" de Roland Siegwart. Específicamente explicado en la
%     sección 3.6. Este hace uso de tres ángulos: Alpha (Ángulo entre la
%     línea de orientación del robot y la línea que se dibuja del robot a
%     la meta), Beta (Ángulo entre la línea que se dibuja del robot a la
%     meta y la horizontal del marco de referencia global / el eje X de
%     matlab) y Rho_p (La distancia entre la meta y el centroide del
%     robot). Utilizando las constantes K_Rho, K_Alpha y K_Beta, se calcula
%     la velocidad angular (w = K_Alpha * Alpha + K_Beta * Beta) y lineal 
%     (v = K_Rho * Rho_p).
%
%   - Lyapunov: Controlador similar al controlador de pose simple de
%     Siegwart. La diferencia es que este intenta asegurar que el estado
%     del sistema converga asintóticamente a (Rho_p, Alpha, Beta) = [0 0
%     Beta]. Para asegurar dicha convergencia hace uso del criterio de
%     estabilidad de Lyapunov. Para esto, se hace uso de una ecuación de
%     energía interna de lyapunov con la forma V = 0.5*Rho_p^2 +
%     0.5*Alpha^2. Luego de los cálculos respectivos (Nadalini, pág. 31),
%     las reglas de actualización resultantes son v = K_Rho * Rho_p *
%     cos(Alpha) y w = K_Rho * sin(Alpha) * cos(Alpha) + K_Alpha * Alpha.
%
%   - Closed-Loop Steering: Controlador basado en la investigación de Park
%     y Kuipers en el paper "A Smooth control law for graceful motion of
%     differential wheeled mobile robots in 2D environment". Aldo tuvo
%     algunos problemas al implementarlo, entonces el controlador no
%     funciona totalmente bien. Requiere de mejoras. No se recomienda
%     utilizarlo.
%
%   - LQR: Control LQR diseñado utilizando la función lqr(A,B,Q,R) de 
%     Matlab donde A = [0 0; 0 0], B = [1 0; 0 1], R = B y Q = B*0.01.
%     Utilizando este controlador se observaron trayectorias casi rectas
%     hacia la meta. No ventajoso para espacios de búsqueda con obstáculos.
%     Parámetros adicionales: RadioCuerpoPuck
%
%   - LQI: Control LQI diseñado utilizando la función lqr(A,B,Q,R) de 
%     Matlab donde A = 0, B = I, C = I, Q = eye(4) y R = 2000 * eye(2). 
%     Las matrices resultantes K y Ki fueron 0.2127 * eye(2) y -0.0224 *
%     eye(2) respectivamente. Resultados casi idénticos a los del LQR, con
%     la diferencia que este presentaba velocidades más "suaves".
%     Parámetros adicionales: RadioCuerpoPuck, Posicion_GlobalBest
%
% -------------------------------------------------------------------------

% Variables que mantienen su valor entre diferentes llamadas a una función
persistent ErrorAcumulado

% El usuario debe pasar: 1 meta para todos los Pucks o 1 meta por Puck.
% Si se pasa un número irregular de metas, se retorna un error.
if ~(size(Meta,1) == 1 || size(Meta,1) == size(PuckPosicion_Actual,1))
   error("El número de metas no coincide con el número de Pucks. Porfavor pasar 1 meta para todos los Pucks o 1 meta por Puck"); 
end
    
switch ControllerType
    % Controlador de pose simple de robot
    case "Pose Simple"
        K_Rho = 0.1;
        K_Alpha = 0.5;
        K_Beta = -0.05;
        
        % Rho_p: Distancia de todos los Pucks a la Meta
        [~,Rho_p] = dsearchn(Meta,PuckPosicion_Actual);
        
        % Error de posición
        ErrorPos = Meta - PuckPosicion_Actual;
        
        % Ángulo de línea entre meta y robot (Theta goal)
        % Para que todos los ángulos estén entre los mismos límites se
        % mapean los valores de 0 a 2pi (wrapTo2Pi)
        Theta_g = atan2(ErrorPos(:,2),ErrorPos(:,1));
        Theta_g = wrapTo2Pi(Theta_g);
        
        % Orientación actual del robot
        Theta_o = PuckOrientacion_Actual;
        Theta_o = wrapTo2Pi(Theta_o);
        
        % Error de orientación
        % Se utiliza "angdiff()" para calcular la diferencia entre ambos
        % ángulos para tomar en cuenta que ángulos como "2pi" y "0" son
        % virtualmente el mismo ángulo. Entonces, usando esta función, 
        % la diferencia entre 6.27 (Casi 2pi) y 0.78 (Casi pi/4), será muy
        % cercana a la diferencia entre 0 y 0.78 (Casi pi/4). Los ángulos 
        % resultantes están acotados entre -pi y pi.
        Alpha = angdiff(Theta_o, Theta_g);
        
        % Beta = - Theta_o - Alpha (Nadalini, pág 29), pero Theta_o está 
        % entre 0 y 2pi luego de usar "wrapTo2Pi". Se le resta pi, para 
        % regresarlo entre [-pi, pi] y que así esté entre el mismo rango de
        % Alpha. Beta estará entre -pi y pi
        Theta_o = Theta_o - pi;
        Beta = angdiff(Theta_o, -Alpha);
        
        % Velocidades Lineal y Angular (Nadalini, pág. 29)
        VelLineal = K_Rho .* Rho_p;
        VelAngular = K_Alpha .* Alpha + K_Beta .* Beta;
        
    
    % Controlador de Pose con Criterio de Estabilidad de Lyapunov
    case "Lyapunov"
        
        % Parámetros de controlador
        K_Rho = 0.1;
        K_Alpha = 0.5;
        
        % Rho_p: Distancia de todos los Pucks a la Meta
        [~,Rho_p] = dsearchn(Meta,PuckPosicion_Actual);
        
        % Error de posición
        ErrorPos = Meta - PuckPosicion_Actual;
        
        % Ángulo de línea entre meta y robot (Theta goal)
        % Para que todos los ángulos estén entre los mismos límites se
        % mapean los valores de 0 a 2pi (wrapTo2Pi)
        Theta_g = atan2(ErrorPos(:,2),ErrorPos(:,1));
        Theta_g = wrapTo2Pi(Theta_g);
        
        % Orientación actual del robot
        Theta_o = PuckOrientacion_Actual;
        Theta_o = wrapTo2Pi(Theta_o);
        
        % Error de orientación
        % Se utiliza "angdiff()" para calcular la diferencia entre ambos
        % ángulos para tomar en cuenta que ángulos como "2pi" y "0" son
        % virtualmente el mismo ángulo. Entonces, usando esta función, 
        % la diferencia entre 6.27 (Casi 2pi) y 0.78 (Casi pi/4), será muy
        % cercana a la diferencia entre 0 y 0.78 (Casi pi/4). Los ángulos 
        % resultantes están acotados entre -pi y pi.
        Alpha = angdiff(Theta_o, Theta_g);
        
        % Velocidades Lineal y Angular (Nadalini, pág. 31)
        VelLineal = K_Rho .* Rho_p .* cos(Alpha);
        VelAngular = (K_Rho .* sin(Alpha) .* cos(Alpha)) + K_Alpha .* Alpha;
    
    % Controlador por Closed-Loop Steering
    % Controlador no recomendado. Aldo tuvo problemas al implementarlo.
    case "Closed-Loop Steering"
        K1 = 1;
        K2 = 10;
        
        % Parámetros de controlador
        K_Rho = 0.1;
        
        % Rho_p: Distancia de todos los Pucks a la Meta
        [~,Rho_p] = dsearchn(Meta,PuckPosicion_Actual);
        
        % Error de posición
        ErrorPos = Meta - PuckPosicion_Actual;
        
        % Ángulo de línea entre meta y robot (Theta goal)
        % Para que todos los ángulos estén entre los mismos límites se
        % mapean los valores de 0 a 2pi (wrapTo2Pi)
        Theta_g = atan2(ErrorPos(:,2),ErrorPos(:,1));
        Theta_g = wrapTo2Pi(Theta_g);
        
        % Orientación actual del robot
        Theta_o = PuckOrientacion_Actual;
        Theta_o = wrapTo2Pi(Theta_o);
        
        % Error de orientación
        % Se utiliza "angdiff()" para calcular la diferencia entre ambos
        % ángulos para tomar en cuenta que ángulos como "2pi" y "0" son
        % virtualmente el mismo ángulo. Entonces, usando esta función, 
        % la diferencia entre 6.27 (Casi 2pi) y 0.78 (Casi pi/4), será muy
        % cercana a la diferencia entre 0 y 0.78 (Casi pi/4). Los ángulos 
        % resultantes están acotados entre -pi y pi.
        Alpha = angdiff(Theta_o, Theta_g);
        
        % Beta = - Theta_o - Alpha (Nadalini, pág 29), pero Theta_o está 
        % entre 0 y 2pi luego de usar "wrapTo2Pi". Se le resta pi, para 
        % regresarlo entre [-pi, pi] y que así esté entre el mismo rango de
        % Alpha. Beta estará entre -pi y pi
        Theta_o = Theta_o - pi;
        Beta = angdiff(Theta_o, -Alpha);
        
        % Velocidad Lineal (Nadalini, pág. 31)
        VelLineal = K_Rho .* Rho_p .* cos(Alpha);
        
        % Velocidad Angular (Nadalini, pág 33)
        VelAngular = (2/5)*(VelLineal ./ Rho_p).*(K2*(Alpha + atan(-K1*Beta)) + ...
                     (1 + (K1./(1 + (K1*Beta).^2))).*sin(Alpha));
        
    % Controlador por Regulador Lineal Cuadrático (LQR)
    case "LQR"
        
        % Se inicializa el error acumulado, en caso aún no tenga valor
        % alguno.
        if isempty(ErrorAcumulado)
            ErrorAcumulado = zeros(size(PuckPosicion_Actual));                             
        end
        
        % Error de posición entre robot y meta
        ErrorPos = PuckPosicion_Actual - Meta;
        
        % Controlador LQR
    	K = 0.1;              	% Parámetros de controlador (Nadalini, pág 82)
        U = -K * (ErrorPos);  	% Retroalimentación (Nadalini, pág 36)
        
        % Actualización de velocidades
        VelLineal = U(:,1).*cos(PuckOrientacion_Actual) + U(:,2).*sin(PuckOrientacion_Actual);
        VelAngular = (-U(:,1).*sin(PuckOrientacion_Actual) + U(:,2).*cos(PuckOrientacion_Actual)) / RadioPuck;
    
    % Controlador Lineal Cuadrático Integral
    case "LQI"

        % Se inicializa el error acumulado, en caso aún no tenga valor
        % alguno.
        if isempty(ErrorAcumulado)
            ErrorAcumulado = zeros(size(PuckPosicion_Actual));                             
        end
        
        % Parámetros de controlador (Nadalini, pág 85 y 86)
        SamplingTime = 0.032;
        Bp = 0.95;             	% Amortiguamiento de control proporcional
        Bi = 0.01;              % Amortiguamiento de control integral                      
        KLQR = -0.2127;         % Control
        KLQI = -0.0224;
        
        % Error de posición entre robot y meta
        ErrorPos = Meta - PuckPosicion_Actual;
        
        % Controlador LQI (u = -K*e - Ki * Ei)
        U = (-KLQR * (1 - Bp) * ErrorPos) - (KLQI * ErrorAcumulado);
        
        % Integración numérica de error entre posición actual y meta
        ErrorAcumulado = ErrorAcumulado + (ErrorPos * SamplingTime);
        
        % Frenado de intregrador para evitar oscilaciones en posiciones
        ErrorAcumulado = (1 - Bi) * ErrorAcumulado;
        
        % Mapeo de velocidades LQI a velocidades de robot por medio de
        % difeomorfismo.
        VelLineal = U(:,1).*cos(PuckOrientacion_Actual) + U(:,2).*sin(PuckOrientacion_Actual);
        VelAngular = (-U(:,1).*sin(PuckOrientacion_Actual) + U(:,2).*cos(PuckOrientacion_Actual)) / RadioPuck;

end

