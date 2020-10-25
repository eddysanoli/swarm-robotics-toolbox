function [W] = ComputeInertia(InertiaType, varargin)
% COMPUTEINERTIA Cálculo del coeficiente de inercia W (omega). 
% ------------------------------------------------------------
% Tipos de inercia disponibles:
%
%   - Constante
%       IntertiaType = "Constant"
%       Uso: 
%                   COMPUTEINERTIA("Constant",W)
%
%       Info: El enjambre aumenta su velocidad de convergencia y modera la
%       dispersión de las partículas. Valores entre 0.8 y 1.2 presentan un
%       buen equilibrio entre exploración y rapidez de convergencia.
%
%   - Linealmente Decreciente
%       InertiaType = "Linear"
%       Uso:  
%             Full Control - COMPUTEINERTIA("Linear", IterActual, Wmax, Wmin, IteracionesMax)
%        Default Wmax/Wmin - COMPUTEINERTIA("Linear", IterActual, IteracionesMax)         
%
%       Info: Se recomienda un Wmax = 1.4 y un Wmin = 0.5. Con estos valores
%       se favorece la dispersión del enjambre para encontrar el mínimo global
%       al inicio la búsqueda y luego se acelera la convergencia del enjambre 
%       hacia ese punto, al llegar al valor de Wmin.
%
%   - Decreciente Caótica
%       InertiaType = "Chaotic"
%       Uso: 
%           Full Control - COMPUTEINERTIA("Chaotic", IterActual, Wmax, Wmin, IteracionesMax, Z0)
%             Default Z0 - COMPUTEINERTIA("Chaotic", IterActual, Wmax, Wmin, IteracionesMax)
%
%       Info: Se elige un valor inicial de Z (Z0) entre [0,1] y se hace un 
%       mapeo logístico. Esta función logra darle más precisión al enjambre 
%       a la hora de encontrar el mínimo global, no obstante, no afecta la
%       rapidez de la convergencia. Z0 default = 0.2.
%
%   - Aleatoria
%       InertiaType = "Random"
%       Uso: 
%                   COMPUTEINERTIA("Random")
%
%       Info: Esta asignación de inercia mejora la habilidad del enjambre
%       de salir de mínimos locales y reduce el número total de iteraciones
%       necesarias para que el algoritmo converja.
%
%   - Natural Exponent Inertia Weight Strategy (e1-PSO)
%       InertiaType = "Exponent1"
%       Uso:  
%             Full Control - COMPUTEINERTIA("Exponent1", IterActual, Wmax, Wmin, IteracionesMax)
%        Default Wmax/Wmin - COMPUTEINERTIA("Exponent1", IterActual, IteracionesMax)         
%
%       Info: Esta estrategia de ecuación exponencial reduce el error promedio
%       para que el enjambre logre llegar al punto mínimo utilizando un número 
%       de iteraciones constante. Permite que al inicio de la ejecución del 
%       algoritmo se tenga una buena exploración del espacio de búsqueda y se 
%       tenga una aceleración exponencial de la velocidad de convergencia al 
%       aumentar las iteraciones. Valores Default de W: Wmax = 1.4 / Wmin = 0.5.

switch InertiaType
    % Inercia Constante
    % Obtenido de: A Modified Particle Swarm Optimizer (Shi & Eberhart, 1998).
    case "Constant"
        W = varargin{1};
    
    % LDIW-PSO: Inercia Lineal Decreciente
    % Obtenido de: On the Performance of Linear Decreasing Inertia Weight
    % Particle Swarm Optimization for Global Optimization (2013).
    case "Linear"
        switch numel(varargin)
            case 2                          % Uso de Wmax y Wmin default
                Wmax = 1.4; Wmin = 0.5;
                Iter = varargin{1};
                MaxIter = varargin{2};
            otherwise                       % Control total de parámetros
                Iter = varargin{1};
                Wmax = varargin{2};
                Wmin = varargin{3};
                MaxIter = varargin{4}; 
        end
        
        W = Wmax - ((Wmax - Wmin) * (Iter/MaxIter));
    
    % CDIW-PSO: Inercia Decreciente Caótica
    % Obtenido de: On the Performance of Linear Decreasing Inertia Weight
    % Particle Swarm Optimization for Global Optimization (2013).
    case "Chaotic"
        persistent Z
        Iter = varargin{1};
        Wmax = varargin{2};
        Wmin = varargin{3};
        MaxIter = varargin{4};
        
        if Iter <= 1
            switch numel(varargin)
                case 4                      % Valor default para Z0
                    Z = 0.2;
                otherwise                   % Control total de parámetros
                    Z = varargin{5};
            end
        end
        
        Z = 4 * Z * (1 - Z);
        W = ((Wmax - Wmin) * (MaxIter - Iter)/MaxIter) + (Wmin * Z);
    
    % Inercia Aleatoria
    % Obtenido de: Inertia Weight Strategies in Particle Swarm Optimization (2012).
    case "Random"
        W = 0.5 + rand()/2;
    
    % e1-PSO: Natural Exponent Inertia Weight Strategy
    % Obtenido de: Inertia Weight Strategies in Particle Swarm Optimization (2012).
    case "Exponent1"
        switch numel(varargin)
            case 2                          % Uso de Wmax y Wmin default
                Wmax = 1.4; Wmin = 0.5;
                Iter = varargin{1};
                MaxIter = varargin{2};
            otherwise                       % Control total de parámetros
                Iter = varargin{1};
                Wmax = varargin{2};
                Wmin = varargin{3};
                MaxIter = varargin{4}; 
        end
        
        W = Wmin + (Wmax - Wmin) * exp((-1*Iter)/(MaxIter/10));
        
end

% NOTA SOBRE USO DE VARARGIN: La variable "varargin" consiste de un dato
% tipo celda que puede tener longitud variable. Esto permite la creación de
% funciones con un número de inputs variable, donde cada input puede llegar
% a tener un tipo de dato distinto. Es por esto que en los casos donde la
% inercia puede utilizarse en su valor "default" o "custom" se comprueba el
% número de elementos dentro de "varargin" (numel()). Si el número de
% elementos = 2 se asume que se tomará el valor default. De lo contrario
% se asume que se recibirán 4 parámetros adicionales a "InertiaType".

end
