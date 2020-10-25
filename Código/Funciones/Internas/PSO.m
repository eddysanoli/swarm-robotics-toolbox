classdef PSO < handle
% PSO Clase que permite crear y correr diferentes instancias del algoritmo 
% de "Particle Swarm Optimization" con una variedad de parámetros.
% -------------------------------------------------------------------------
%
% Propiedades: 
%
%   Propiedades Generales
%   - NoIteracionesMax: Cantidad máxima de iteraciones que puede llegar a
%     durar una corrida del algoritmo PSO.
%   - NoParticulas: Cantidad de partículas a simular.
%   - NoDimensiones: Número de dimensiones o coordenadas asociadas a cada
%     partícula. En la mayor parte del Toolbox se intenta mantener este
%     parámetro en 2 (X,Y), aunque la estructura permite generalizar el
%     algoritmo para mayores dimensionalidades.
%   - IteracionActual: Iteración actual en la que se encuentra el algoritmo
%     PSO en caso ya se haya iniciado una corrida.
%
%   Posición y Velocidad
%   - Posicion_Actual: Dims = (NoParticulas, NoDimensiones). Coordenadas 
%     de las partículas del algoritmo en la iteración actual. Por defecto
%     se ordenan en columnas (X,Y,...).
%   - Posicion_Previa: Dims = (NoParticulas, NoDimensiones). Coordenadas 
%     de las partículas en la iteración previa a la actual. Por defecto
%     se ordenan en columnas (X,Y,...).
%   - Posicion_LocalBest: Dims = (NoParticulas,NoDimensiones). La mejor 
%     posición obtenida por cada partícula hasta el momento (Posición local 
%     con el menor costo asociado).
%   - Posicion_GlobalBest: Dims = (1,NoDimensiones). La mejor posición 
%     obtenida entre todas las partículas hasta el momento (Posición global 
%     con el menor costo asociado).
%   - Posicion_History: Celda que contiene las posiciones de las partículas
%     por cada iteración realizada hasta el momento del algoritmo.
%   - Velocidad: Dims = (NoParticulas,NoDimensiones). Velocidad 
%     (Descompuesta en sus componentes) correspondiente a cada una de las
%     partículas.
%
%   Inercia
%   - TipoInercia: Tipo de inercia a emplear. Escribir "help
%     ComputeInertia" para más información.
%   - W: Coeficiente de inercia. Coeficiente que multiplica a la velocidad
%     de las partículas en la ecuación de actualización de velocidad.
%     Puede obtenerse usando diferentes métodos dentro de ComputeInertia.m
%     o elegirse como una constante manual.
%   - Wmin: Valor mínimo de W.
%   - Wmax: Valor máximo de W.
%
%   Coeficientes de Constricción 
%   - Chi: Constante de restricción propuesta por Kennedy (2007). Esta se
%     encarga de acotar la nueva velocidad de las partículas.
%   - Phi1: Constante utilizada como límite superior para la generación de
%     un número aleatorio uniformemente distribuido entre 0 y Phi1. Este
%     multiplica la parte "local" de la ecuación de actualización de
%     velocidad.
%   - Phi2: Constante utilizada como límite superior para la generación de
%     un número aleatorio uniformemente distribuido entre 0 y Phi2. Este
%     multiplica la parte "social" de la ecuación de actualización de
%     velocidad.
%
%   Restricciones
%   - TipoRestricción: Restricciones que se le colocan a la ecuación de
%     actualización de velocidad de las partículas. Existen tres tipos:
%     "Inercia", "Constricción" y "Mixto".
%   - VelMin: Cota inferior o velocidad mínima a la que puede llegar la
%     velocidad de una partícula.
%   - VelMax: Cota superior o velocidad máxima a la que puede llegar la
%     velocidad de una partícula.
%   - LimsX: Límites de la mesa de trabajo en X.
%   - LimsY: Límites de la mesa de trabajo en Y..
%
%   Costo
%   - FuncionCosto: El tipo de función de costo a optimizar por las
%     partículas del algoritmo. Escribir "help CostFunction" para más
%     información.
%   - Costo_Local: Dims = (NoParticulas,1). Valor de costo para cada
%     partícula en su posición actual.
%   - Costo_LocalBest: Dims = (1,1). El valor de costo máximo obtenido por
%     todas las partículas en la iteración actual.
%   - Costo_GlobalBest: Dims = (1,1). El valor de costo máximo obtenido por
%     todas las partículas en todas las iteraciones hasta ahora.
%
% -------------------------------------------------------------------------
% 
% Métodos
%
%   - PSO: Creación de un objeto de tipo PSO.
%   - InitPSO: Inicialización de las posiciones, velocidades y costos de
%     partículas del algoritmo.
%   - SetRestricciones: Se elige el tipo de restricciones a colocar en la
%     ecuación de actualización de la velocidad de las partículas.
%   - RunStandardPSO: Se ejecuta el algoritmo PSO. Se puede ejecutar una
%     sola iteración por llamada a este método o ejecutar una corrida
%     completa hasta converger.
%
% Nota: Para más información sobre cada método, escribir en consola "help
% PSO.NombreMetodo". Cada método tiene su propia documentación.
% 
% -------------------------------------------------------------------------
    
    properties
        % Posiciones y Velocidades
        Posicion_Actual
        Posicion_Previa
        Posicion_LocalBest
        Posicion_GlobalBest
        Posicion_History
        Velocidad
        
        % Propiedades Generales
        NoIteracionesMax
        NoParticulas
        NoDimensiones
        IteracionActual
        Bordes_RegionPartida
        
        % Parámetros de Inercia
        W
        Wmax
        Wmin
        TipoInercia
        
        % Parámetros de Coeficientes de Constricción
        Chi
        Phi1
        Phi2
        
        % Criterio de convergencia
        CriterioConv
        
        % Restricciones
        TipoRestriccion
        VelMin
        VelMax
        LimsX
        LimsY
                
        % Costo
        FuncionCosto
        Costo_Local
        Costo_LocalBest
        Costo_GlobalBest  
        Costo_GlobalBestHistory
    end
    
    methods
      
        function obj = PSO(NoParticulas, NoDimensiones, Func_Costo, CriterioConv, Iter_Max, Bordes_RegionPartida)
            % PSO Rutina que permite crear un objeto de la clase PSO.
            % Se configura la función de costo a utilizar, el criterio de
            % convergencia, el número de iteraciones máximas que puede
            % utilizar el algoritmo, y los bordes de la región de partida
            % de las partículas.
            % -------------------------------------------------------------
            % Inputs: 
            %   - NoParticulas: Cantidad de partículas a simular.
            %   - NoDimensiones: Cantidad de dimensiones para las posicio-
            %     nes y velocidades de las partículas. Si se iguala a 2 por
            %     ejemplo, las partículas se moverán sobre el plano (X,Y),
            %     si se coloca 3, las partículas se podrán mover sobre el
            %     espacio (X,Y,Z), etc.
            %   - Func_Costo: Función de costo a minimizar. Escribir "help
            %     CostFunction" para más información.
            %   - CriterioConv: Criterio a utilizar para determinar si el
            %     algoritmo ha convergido. Escribir "help
            %     getCriterioConvergencia" en consola para más info.
            %   - IterMax: Iteraciones máximas que puede llegar a durar el
            %     algoritmo de PSO. 
            %   - Bordes_RegionPartida: Límites en X y Y para la región
            %     rectangular en la que se podrán posicionar las partículas
            %     al inicializar el algoritmo. 
            %
            %       Forma: [LimXInf LimXSup ; LimYInf LimYSup]
            %
            % Outputs:
            %   - Obj: Objeto de la clase PSO que contiene todas las
            %     propiedades listadas al escribir "help PSO".
            %
            % -------------------------------------------------------------
            
            % Cantidad de partículas a simular
            obj.NoParticulas = NoParticulas;
            
            % Cantidad de dimensiones para las posiciones y velocidades de
            % las partículas.
            obj.NoDimensiones = NoDimensiones;
            
            % Historial de Posición 
            obj.NoIteracionesMax = Iter_Max;
            
            % Costo y Global Best
            obj.FuncionCosto = Func_Costo;                                  
            
            % Bordes de la región de partida de la que saldrán las
            % partículas
            obj.Bordes_RegionPartida = Bordes_RegionPartida;

            % Se configura el criterio de convergencia a utilizar después
            obj.CriterioConv = CriterioConv;
            
        end
        
        function InitPSO(obj, EnvironmentParams)
            % INITPSO Rutina de inicialización para un objeto de tipo PSO. 
            % Se inicializan los datos de posición y velocidad de las
            % partículas, su costo inicial y la iteración actual.
            % -------------------------------------------------------------
            % Inputs: 
            %   - EnvironmentParams: Parámetros adicionales requeridos por
            %     la función de costo elegida. 
            %
            % -------------------------------------------------------------
            
            % Posición (Random) de todas las partículas. Distribución
            % uniforme a lo largo de la región de partida.
            obj.Posicion_Actual = zeros(obj.NoParticulas, obj.NoDimensiones);
            
            for i = 1:obj.NoDimensiones
                obj.Posicion_Actual(:,i) = unifrnd(obj.Bordes_RegionPartida(i,1), obj.Bordes_RegionPartida(i,2), [obj.NoParticulas 1]);               
            end
            
            % Posición Previa, Posición Local Best y Velocidad
            obj.Posicion_Previa = obj.Posicion_Actual;                      % Memoria con la posición previa de todas las partículas.               Dims: NoParticulas X VarDims
            obj.Posicion_LocalBest = obj.Posicion_Actual;                  	% Las posiciones que generaron los mejores costos en las partículas     Dims: NoParticulas X VarDims
            obj.Velocidad = zeros(size(obj.Posicion_Actual));               % Velocidad de todas las partículas. Inicialmente 0.                    Dims: NoParticulas X VarDims
            
            % Creación del Historial de Posiciones.
            obj.Posicion_History = cell(obj.NoDimensiones,1);              	% Celda con arrays guardando todas las posiciones.                      Dims: VarDims X 1
            
            for i = 1:obj.NoDimensiones
                % Fila "i" de "Posicion_History" = Matriz de ceros para la dimensión "i"
                obj.Posicion_History{i} = zeros(obj.NoParticulas,obj.NoIteracionesMax);  
                
                % Array dentro de la fila "i" de "Posicion_History" = Todos los valores de posición para la dimensión "i".
                obj.Posicion_History{i}(:,1) = obj.Posicion_Actual(:,i);    
            end
            
            % Evaluación del costo en la posición actual de la partícula.           
            % Dims: NoPartículas X 1 (Vector Columna)             
            obj.Costo_Local = CostFunction(obj.Posicion_Actual, obj.FuncionCosto, EnvironmentParams{:});                    	
            obj.Costo_LocalBest = obj.Costo_Local;
            
            % Obtención del Global Best Inicial
            [obj.Costo_GlobalBest, Fila] = min(obj.Costo_LocalBest);        % "Global best": El costo más pequeño del vector "CostoLocal"           Dims: Escalar
            obj.Posicion_GlobalBest = obj.Posicion_Actual(Fila, :);        	% "Global best": Posición que genera el costo más pequeño               Dims: 1 X VarDims
            
            obj.Costo_GlobalBestHistory = zeros(obj.NoIteracionesMax,1);
            obj.Costo_GlobalBestHistory(1) = obj.Costo_GlobalBest;
            
            % La etapa de inicialización consiste de la iteración 1 del
            % algoritmo
            obj.IteracionActual = 1;   
            
        end
        
        function SetRestricciones(obj, Restriccion, LimsX, LimsY, varargin)
            % -------------------------------------------------------------
            % SETRESTRICCIONES Restricciones aplicadas a la regla de
            % actualización de la velocidad de las partículas.  
            % -------------------------------------------------------------
            % Inputs:
            %   - Restriccion: Tipo de restricción a utilizar. Están
            %     disponibles tres modos: "Inercia", "Constriccion" y 
            %     "Mixto".
            %   - LimsX: Límites de la mesa de trabajo en X.
            %   - LimsY: Límites de la mesa de trabajo en Y.
            %
            % Parámetros Modificables
            %   - 'Wmax': Valor máximo que puede adquirir la inercia.
            %     Default = 0.9.
            %   - 'Wmin': Valor mínimo que puede adquirir la inercia.
            %     Default = 0.4.
            %   - 'Chi': Restricción a la nueva velocidad total.
            %     Default = 1.
            %   - 'Phi1': Límite superior para la generación de valores
            %     uniformemente distribuidos que multiplican la sección
            %     cognitiva de las partículas. Default = 2.05.
            %   - 'Phi2': Límite superior para la generación de valores
            %     uniformemente distribuidos que multiplican la sección
            %     social de las partículas. Default = 2.05.
            %   - 'Kappa': Parámetro usado para calcular Chi. Default = 1.
            %   - 'W': Inercia. Si se utiliza un modo diferente a "Inercia"
            %     se puede setear el valor que tendrá esta constante.
            %     Default = 1.
            %
            % -------------------------------------------------------------
            % 
            % Opciones "Restriccion"
            %   - "Constricción": Utilizar el coeficiente de constricción
            %     (Chi) en base a las ideas de Kennedy (2007) limitando a 
            %     Vmax y Xmax.
            %   - "Inercia": Utilizar un coeficiente de inercia para
            %     limitar la influencia de la velocidad previa en la regla
            %     de actualización de velocidad de partículas. Escribir
            %     "help ComputeInertia" para más información.
            %   - "Mixto": Mezclar ambos métodos. Método utilizado por Aldo
            %     Nadalini en su tésis.
            %
            % -------------------------------------------------------------
            
            IP = inputParser;
            
            % Inputs Obligatorios / Requeridos
            IP.addRequired('Restriccion', @isstring);
            IP.addRequired('LimsX', @isnumeric);
            IP.addRequired('LimsY', @isnumeric);
            
            % Parámetros Opcionales (Usuario debe escribir su nombre
            % seguido del valor que desea).
            IP.addParameter('TipoInercia', "Linear", @isstring);
            IP.addParameter('Wmax', 0.9, @isnumeric);
            IP.addParameter('Wmin', 0.4, @isnumeric);
            IP.addParameter('Chi', 1, @isnumeric);
            IP.addParameter('Phi1', 2.05, @isnumeric);
            IP.addParameter('Phi2', 2.05, @isnumeric);
            IP.addParameter('Kappa', 1, @isnumeric);
            IP.addParameter('W', 1, @isnumeric);
            
            % Se ordenan las variables de entrada contenidas en IP.Results
            % según los inputs previos
            IP.parse(Restriccion, LimsX, LimsY, varargin{:});
            
            obj.TipoInercia = IP.Results.TipoInercia;
            obj.LimsX = IP.Results.LimsX;
            obj.LimsY = IP.Results.LimsY;
            obj.TipoRestriccion = IP.Results.Restriccion;
            obj.Wmax = IP.Results.Wmax; 
            obj.Wmin = IP.Results.Wmin;

            switch Restriccion

                % Coeficiente de Inercia ====
                % Para el coeficiente de inercia, se debe seleccionar el método que se desea utilizar. 
                % En total se implementaron 5 métodos distintos. Escribir "help ComputeInertia" para 
                % más información.

                case "Inercia"
                    % Cálculo de la primera constante de inercia.
                    obj.W = ComputeInertia(obj.TipoInercia, 1, obj.Wmax, obj.Wmin, obj.NoIteracionesMax);  
                    
                    Lims = [LimsX LimsY];
                    obj.VelMax = 0.2*diff(Lims);                                    % Velocidad máx: Dims = (1,2). Valor máx = 20% del ancho/alto del plano 
                    obj.VelMin = -obj.VelMax;                                    	% Velocidad mín: Dims = (1,2). Negativo de la velocidad máxima
                    obj.Chi = IP.Results.Chi;                                      	% Igualado a 1 para que el efecto del coeficiente de constricción sea nulo
                    obj.Phi1 = 1; 
                    obj.Phi2 = 1;

                % Coeficiente de Constricción ====
                % Basado en la constricción tipo 1'' propuesta en el paper por Clerc y Kennedy (2001) 
                % titulado "The Particle Swarm - Explosion, Stability and Convergence". Esta constricción 
                % asegura la convergencia siempre y cuando Kappa = 1 y Phi = Phi1 + Phi2 > 4.

                case "Constriccion"
                    Kappa = IP.Results.Kappa;                                       % Modificable. Valor recomendado = 1
                    obj.Phi1 = IP.Results.Phi1;                                  	% Modificable. Coeficiente de aceleración local. Valor recomendado = 2.05.
                    obj.Phi2 = IP.Results.Phi2;                                  	% Modificable. Coeficiente de aceleración global. Valor recomendado = 2.05
                    Phi = obj.Phi1 + obj.Phi2;
                    obj.Chi = 2*Kappa / abs(2 - Phi - sqrt(Phi^2 - 4*Phi));
                    
                    Lims = [LimsX LimsY];
                    obj.W = IP.Results.W;
                    obj.VelMax = Lims(2,:);                                      	% Velocidad máx: Valor máximo de posición en X y Y
                    obj.VelMin = Lims(1,:);                                         % Velocidad mín: Valor mínimo de posición en X y Y

                % Ambos Coeficientes (Mixto) ====
                % Utilizado por Aldo Nadalini en su tésis "Algoritmo Modificado de Optimización de 
                % Enjambre de Partículas (MPSO) (2019). Chi se calcula de la misma manera, pero se
                % utiliza un Phi1 = 2, Phi2 = 10 y el coeficiente de inercia exponencial decreciente.

                case "Mixto"
                    Kappa = IP.Results.Kappa;                                       % Valor recomendado = 1
                    obj.Phi1 = 2;                                                   % Valor recomendado = 2
                    obj.Phi2 = 10;                                                  % Valor recomendado = 10
                    Phi = obj.Phi1 + obj.Phi2;
                    obj.Chi = 2*Kappa / abs(2 - Phi - sqrt(Phi^2 - 4*Phi));

                    obj.TipoInercia = "Exponent1";                                 	% Tipo de inercia recomendada = "Exponent1"
                    obj.Wmax = 1.4; obj.Wmin = 0.5;
                    obj.W = ComputeInertia(obj.TipoInercia, 1, obj.NoIteracionesMax); 	% Cálculo de la primera constante de inercia utilizando valores default (1.4 y 0.5).

                    obj.VelMax = [inf inf];                                      	% Velocidad máx: Sin restricción en X y Y
                    obj.VelMin = [-inf -inf];                                      	% Velocidad mín: Sin restricción en X y Y

            end
        end
        
        function [varargout] = RunStandardPSO(obj, TipoEjecucion, Meta, EnvironmentParams)
            % -------------------------------------------------------------
            % RUNSTANDARDPSO Ejecutar el algoritmo de PSO con los
            % con los parámetros dados.
            % -------------------------------------------------------------
            % Inputs:
            %   - TipoEjecucion: Existen dos modos de ejecución: "Full" y
            %     "Steps". En "Full" el algoritmo se ejecuta hasta llegar a
            %     la iteración final o la IterMax. En "Step" el algoritmo
            %     ejecuta una iteración por cada llamada al método.
            %   - Meta: Punto o puntos a los que deben llegar a la
            %     partícula ya que consisten de los mínimos globales de la
            %     función de costo.
            %   - EnvironmentParams: Parámetros del entorno (Obstáculos,
            %     dimensiones de mesa, etc.). Requerido para evaluar
            %     algunas funciones de costo.
            %
            % -------------------------------------------------------------
            
            switch TipoEjecucion
                case "Steps"
                    IteracionesMax = 2;
                    
                case "Full"
                    IteracionesMax = obj.NoIteracionesMax;
            end
            
            for i = 2:IteracionesMax
                R1 = rand([obj.NoParticulas obj.NoDimensiones]);                                            % Números normalmente distribuidos entre 0 y 1
                R2 = rand([obj.NoParticulas obj.NoDimensiones]);
                obj.Posicion_Previa = obj.Posicion_Actual;                                                  % Se guarda la posición actual como la previa antes de sobre-escribir la actual.             

                % Actualización de Velocidad de Partículas
                obj.Velocidad = obj.Chi * (obj.W * obj.Velocidad ...                                      	% Término inercial
                              + obj.Phi1 * R1 .* (obj.Posicion_LocalBest - obj.Posicion_Actual) ...        	% Componente cognitivo
                              + obj.Phi2 * R2 .* (obj.Posicion_GlobalBest - obj.Posicion_Actual));        	% Componente social

                % Acotado de velocidades en X para impedir velocidades muy
                % grandes o muy pequeñas.
                obj.Velocidad(:,1) = max(obj.Velocidad(:,1), obj.VelMin(1));                               	% Si VelocidadX < VelMinX, entonces VelocidadX = VelMinX
                obj.Velocidad(:,1) = min(obj.Velocidad(:,1), obj.VelMax(1));                               	% Si VelocidadX > VelMaxX, entonces VelocidadX = VelMaxX
                
                % Cota de Velocidad en Y
                obj.Velocidad(:,2) = max(obj.Velocidad(:,2), obj.VelMin(2));                               	% Si VelocidadY < VelMinY, entonces VelocidadY = VelMinY
                obj.Velocidad(:,2) = min(obj.Velocidad(:,2), obj.VelMax(2));
                
                % Actualización de Posición de Partículas
                obj.Posicion_Actual = obj.Posicion_Actual + obj.Velocidad;                                  % Actualización "discreta" de la posición. El algoritmo de PSO original asume un sampling time = 1s.
                
                % Acotado de posiciones en X
                obj.Posicion_Actual(:,1) = max(obj.Posicion_Actual(:,1), obj.LimsX(1));                    	% Se acotan las posiciones de la misma forma en que se acotaron las velocidades
                obj.Posicion_Actual(:,1) = min(obj.Posicion_Actual(:,1), obj.LimsX(2));
                obj.Posicion_Actual(:,2) = max(obj.Posicion_Actual(:,2), obj.LimsY(1));                    	% Se acotan las posiciones de la misma forma en que se acotaron las velocidades
                obj.Posicion_Actual(:,2) = min(obj.Posicion_Actual(:,2), obj.LimsY(2));

                % Cálculo de Costo Local para cada Partícula
                obj.Costo_Local = CostFunction(obj.Posicion_Actual,obj.FuncionCosto,EnvironmentParams{:});  % Actualización de los valores del costo.

                % Cálculo del Local Best
                obj.Costo_LocalBest = min(obj.Costo_LocalBest, obj.Costo_Local);                            % Se sustituyen los costos que son menores al "Local Best" previo
                Costo_Change = (obj.Costo_Local < obj.Costo_LocalBest);                                     % Vector binario que indica con un 0 cuales son las filas de "Costo_Local" que son menores que las filas de "PartCosto_LocalBest"
                obj.Posicion_LocalBest = obj.Posicion_LocalBest .* Costo_Change + obj.Posicion_Actual;      % Se sustituyen las posiciones correspondientes a los costos a cambiar en la linea previa
                                
                % Modificación a Actualización de Global Best basada en
                % paper por Jabandzic y Velagic (2016)
                % [obj.Costo_GlobalBest, Fila] = min(obj.Costo_LocalBest);      
                % obj.Posicion_GlobalBest = obj.Posicion_Actual(Fila, :); 
                
                % Actualización de Global Best
                [Actual_GlobalBest, Fila] = min(obj.Costo_LocalBest);                  	% Actual_GlobalBest = Valor mínimo de entre los valores de "Costo_Local"
                if Actual_GlobalBest < obj.Costo_GlobalBest                            	% Si el "Actual_GlobalBest" es menor al "Global Best" previo 
                    obj.Costo_GlobalBest = Actual_GlobalBest;                         	% Se actualiza el valor del "Global Best" (Costo_GlobalBest)
                    obj.Posicion_GlobalBest = obj.Posicion_Actual(Fila, :);           	% Y la posición correspondiente al "Global Best"
                end 
                        
                % Actualización del Historial del Global Best
                obj.Costo_GlobalBestHistory(i) = obj.Costo_GlobalBest;
                
                % Actualización de Historial de Posiciones
                % Solo válido si la futura actualización corresponde a una
                % iteración menor al número de iteraciones máximas.
                if obj.IteracionActual + 1 <= obj.NoIteracionesMax
                    
                    % Se incrementa el valor de la iteración actual
                    obj.IteracionActual = obj.IteracionActual + 1;
                    
                    % Array dentro de la fila "j" de "Posicion_History" = 
                    % Todos los valores de posición para la dimensión "j".
                    for j = 1:obj.NoDimensiones
                        obj.Posicion_History{j}(:,obj.IteracionActual) = obj.Posicion_Actual(:,j); 	
                    end
                    
                end
                
                % Actualización del coeficiente inercial
                % Solo válido para las restricciones que emplean inercia
                if strcmp(obj.TipoRestriccion, "Inercia") || strcmp(obj.TipoRestriccion, "Mixto")
                    obj.W = ComputeInertia(obj.TipoInercia, obj.IteracionActual, obj.Wmax, obj.Wmin, obj.NoIteracionesMax);
                end
  
                % Evaluación de criterios de convergencia
                [StopPart] = getCriteriosConvergencia(obj.CriterioConv, Meta, obj.Posicion_Actual, obj.IteracionActual/obj.NoIteracionesMax);
                varargout{1} = StopPart;
                
                if StopPart
                    break;      
                end  
            end
            
        end
    end
end

