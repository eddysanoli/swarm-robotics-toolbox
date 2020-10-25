function [Costo, varargout] = CostFunction(X, FunctionName, varargin)
% COSTFUNCTION Evaluación de las posiciones de las partículas (X) en
% la función de costo elegida. 
% -------------------------------------------------------------------------
% Inputs:
%   - X: Matriz (Nx2). Cada fila corresponde a las coordenadas de una
%     partícula. La fila 1 corresponde a la coordenada X y la fila 2
%     corresponde a la coordenada Y.
%   - FunctionName: Función de costo en la que se evaluarán las
%     coordenadas presentes en la matriz X. 9 opciones en total. 
%
% Inputs Opcionales: 
%   FunctionName = "APF"
%   1. LimsX: Límites de la mesa de trabajo en X.
%   2. LimsY: Límites de la mesa de trabajo en Y.
%   3. Meta: Punto a alcanzar por los robots
%
%   FunctionName = "Jabandzic"
%   1. LimsX: Límites de la mesa de trabajo en X.
%   2. LimsY: Límites de la mesa de trabajo en Y.
%   3. Meta: Punto a alcanzar por los robots
%   4. PuckPosicion: Posición actual del robot siguiendo el swarm de
%      partículas PSO.
%   5. ObsMovilPosicion: Posición actual del obstáculo movil más cercano al 
%      robot.
%
% Outputs:
%   - Costo: Vector columna con cada fila consistiendo del costo
%     correspondiente a cada una de las partículas en el swarm.
%
% -------------------------------------------------------------------------
%
% Parámetros:
% 
%   FunctionName = "Dropwave" 
%   - 'NoWaves': Esta función es similar al patrón que se observaría al
%     dejar caer una gota en el agua. El número de "ripples" u olas de la
%     función está dado por este parámetro. Default = 2;
%      
%           Ejemplo de uso: CostFunction(X,"Dropwave",'NoWaves',2);
%
%   FunctionName = "APF"
%   - 'ModoAPF': Referencia utilizada para poder calcular el valor del
%     artificial potential field. Opciones: "Choset" / "Standard".
%     Default = "Choset".
%   - 'ComportamientoAPF': Forma en la que se mezcla el campo atractivo y
%     repulsivo. Opciones: "Aditivo" / "Multiplicativo". Default =
%     "Aditivo".
%
% ------------------------------------------------------------------
%
% Opciones "FunctionName"
%
%   - Schaffer F6 / Schaffer N2: Utilizada originalmente por Kennedy y 
%     Eberhart para evaluar la capacidad de exploración del PSO debido a 
%     las múltiples oscilaciones que presenta. Se puede llamar esta función
%     escribiendo tanto "Schaffer F6" como "Schaffer N2". Mínimo = [0,0].
%
%   - Paraboloid / Sphere: Utilizado en la investigación de J. Bansal et
%     al. para evaluar el rendimiento del parámetro de inercia (W). Útil para 
%     evaluar la velocidad de convergencia del enjambre por su simplicidad.
%     Mínimo = [0,0].
%
%   - Rosenbrock / Banana: El mínimo de esta función se presenta en un
%     angosto valle parabólico. A pesar que el valle es fácil de ubicar, el
%     mínimo comúnmente es dificil de localizar debido a que la pendiente
%     presente en el valle es virtualmente nula. Mínimo = [1,1].
%
%   - Booth: Función simple que puede llegar a describirse como una función
%     "Sphere" descentrada. Mínimo = [0,0]
%
%   - Ackley: Utilizada ampliamente para evaluar susceptibilidad a mínimos
%     locales. Esto se debe a que esta función posee un mínimo absoluto en
%     [0,0], pero la región circundante al valle que contiene este mínimo
%     está repleta de mínimos locales. Mínimo = [0,0].
%
%   - Rastrigin: Función con múltiples mínimos locales. Su superficie es
%     irregular pero sus mínimos locales están uniformemente distribuidos.
%     Mínimo = [0,0].
%
%   - Levy N13: Utilizada para evaluar susceptibilidad a mínimos locales.
%     Mínimo = [1,1].
%
%   - Dropwave: Muy similar a la función "SchafferF6". Similar al forma del
%     agua luego que una gota golpeara su superficie. PARÁMETRO OPCIONAL DE
%     FUNCIÓN: No. de "olas" de la función. 1 Mínimo = [0,0].
%
%   - Himmelblau: Función con múltiples mínimos globales o absolutos. Útil
%     para determinar la influencia de la posición inicial de las partículas
%     sobre la decisión del punto de convergencia final. 4 Mínimos.
%
%   - APF: Función creada utilizando artificial potential fields. Esta
%     genera un campo de potencial o función de costo "custom" que presenta
%     un valle en la meta a alcanzar y montañas de altura casi infinita en
%     donde se presentan obstáculos. Si se permite que un algoritmo de
%     optimización basado en exploración encuentre el mínimo de esta
%     función, lo más común es que este navegue alrededor de los obstáculos
%     (Para evitar máximos) moviéndose hacia la meta, donde se encontraría
%     el mínimo.
%
%   - Jabandzic: Función de costo que mezcla las ideas del PSO y
%     planificación de trayectorias. El algoritmo utiliza un plantamiento
%     muy intuitivo: El robot busca maximizar la distancia hacia paredes y
%     obstáculos, mientras minimiza la distancia hacia la meta. Para
%     poder hacer esta minimización y maximización, emplea PSO como método
%     para resolver el problema de optimización.
%
% ------------------------------------------------------------------
    
    % Valores default para inputs
    defaultModoAPF = "Choset";
    defaultComportamientoAPF = "Aditivo";
    defaultNoWaves = 2;
    
    % Se crea el objeto encargado de "parsear" los inputs
    IP = inputParser;  
    
    % Inputs Obligatorios / Requeridos: Necesarios para el funcionamiento 
    % del programa. La función da error si el usuario no los pasa.                                                     
    IP.addRequired('Coordenadas', @isnumeric);
    IP.addRequired('NombreFuncion', @isstring);
    
    % Inputs Opcionales: El usuario puede o no pasarlos, pero estos deben 
    % ser escritos en orden luego de los "Required". Si no se proporciona
    % un valor Matlab asume un valor "default"
    IP.addOptional('XObs', 0, @isnumeric);
    IP.addOptional('YObs', 0, @isnumeric);
    IP.addOptional('LimsX', [-20 20], @isnumeric);
    IP.addOptional('LimsY', [-20 20], @isnumeric);
    IP.addOptional('Meta', [0 0], @isnumeric);
    IP.addOptional('PuckPosicion', 0, @isnumeric);
    IP.addOptional('ObsMovilPosicion', [0 0], @isnumeric);
    
    % Parámetros: Similar a cuando se utiliza 'FontSize' en plots. El
    % usuario debe escribir el nombre del parámetro a modificar seguido
    % de su valor. Si no se provee un valor Matlab asume uno "default".
    IP.addParameter('ModoAPF', defaultModoAPF, @isstring);
    IP.addParameter('ComportamientoAPF', defaultComportamientoAPF, @isstring);
    IP.addParameter('NoWaves', defaultNoWaves, @isnumeric);
    IP.addParameter('ConstanteM', 10, @isnumeric);
    IP.parse(X,FunctionName,varargin{:});
    
    % Se guardan los inputs "parseados" en variables útiles capaces
    % de ser utilizadas por el programa.
    VerticesObsX = IP.Results.XObs;
    VerticesObsY = IP.Results.YObs;
    LimsX = IP.Results.LimsX;
    LimsY = IP.Results.LimsY;
    Meta = IP.Results.Meta;
    Modo = IP.Results.ModoAPF;
    PuckPosicion = IP.Results.PuckPosicion;
    ObsMovilPosicion = IP.Results.ObsMovilPosicion;
    Comportamiento = IP.Results.ComportamientoAPF;
    NoWaves = IP.Results.NoWaves;
    ConstanteM = IP.Results.ConstanteM;
    
% ------------------------------------------------------------------

    switch FunctionName
        % Paraboloide o Esfera
        % Fuente: https://www.sfu.ca/~ssurjano/spheref.html
        case {"Paraboloid", "Sphere"}                      
            Costo = sum(X.^2, 2);
            
            % Mínimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));    
            varargout{1} = Minimo;
        
        % Griewank Function
        % Fuente: https://www.sfu.ca/~ssurjano/griewank.html
        case "Griewank"
            Sum = sum((X.^2) / 4000, 2);
            
            NoDims = size(X,2);
            NoPuntos = size(X,1);
            Indices = repmat(1:NoDims,NoPuntos,1);
            Prod = prod(cos(X ./ sqrt(Indices)),2);
            
            Costo = Sum - Prod + 1;
            
            % Mínimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;
            
        % Ackley Function
        % Fuente: https://www.sfu.ca/~ssurjano/ackley.html
        case "Ackley"                      
            a = 20; b = 0.2; c = 2*pi; d = size(X,2);              
            Sum1 = -b * sqrt((1/d) * sum(X.^2, 2));
            Sum2 = (1/d) * sum(cos(c*X), 2);
            Costo = -a*exp(Sum1) - exp(Sum2) + a + exp(1);
            
            % Mínimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;

        % Rastrigin Function
        % Fuente: https://www.sfu.ca/~ssurjano/rastr.html
        case "Rastrigin"
            d = size(X,2);                                          
            Costo = 10*d + sum(X.^2 - 10*cos(2*pi*X), 2);
            
            % Mínimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;

        % Levy Function N.13
        case {"Levy N13", "Levy"}
            Costo = sin(3*pi*X(:,1)).^2 ...                        
                    + (X(:,1)-1).^2 .* (1 + sin(3*pi*X(:,2)).^2) ...
                    + (X(:,2) - 1).^2 .* (1 + sin(2*pi*X(:,2)).^2);
                
            Minimo = [1 1];
            varargout{1} = Minimo;

        % Drop Wave Function        
        case "Dropwave"
            
            Costo = -(1 + cos(NoWaves * sqrt(sum(X.^2, 2)))) ./ ...
                     (0.5 * sqrt(sum(X.^2, 2)) + 2);
            
            % Mínimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;
        
        % Schaffer F6 Function
        case {"Schaffer F6", "Schaffer N2"}
            Costo = 0.5 + ((sin(sqrt(sum(X.^2, 2))).^2 - 0.5) ./ ...
                           (1 + (0.001 * sum(X.^2, 2))));
                       
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;
        
        % Rosenbrock / Banana Function
        case {"Rosenbrock", "Banana"}
            
            % Error en caso se alimenten coordenadas de más de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La función de costo" + FunctionName + "únicamente acepta coordenadas bidimensionales"); 
            end
            
            Costo = sum(100*(X(:,2)-X(:,1).^2).^2 + (X(:,1)-1).^2, 2);
            
            Minimo = [1 1];
            varargout{1} = Minimo;
        
        % Booth Function
        case "Booth"
            
            % Error en caso se alimenten coordenadas de más de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La función de costo" + FunctionName + "únicamente acepta coordenadas bidimensionales"); 
            end
            
            Costo = (X(:,1) + 2*X(:,2) - 7).^2 + (2*X(:,1) + X(:,2) - 5).^2;
            
            Minimo = [1 3];
            varargout{1} = Minimo;
        
        % Himmelblau Function
        case "Himmelblau"
            
            % Error en caso se alimenten coordenadas de más de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La función de costo" + FunctionName + "únicamente acepta coordenadas bidimensionales"); 
            end
            
            Costo = (X(:,1).^2 + X(:,2) - 11).^2 + (X(:,1) + X(:,2).^2 - 7).^2;

            Minimo = [      3       2; 
                      -2.8051  3.1313; 
                      -3.7793 -3.2831; 
                       3.5844 -1.8481];
            varargout{1} = Minimo;
        
        % Six-hump Camel Function
        case {"Six-Hump Camel", "Camel"}
            
            if size(X,2) > 2
               error("Error: La función de costo" + FunctionName + "únicamente acepta coordenadas bidimensionales"); 
            end
            
            X1 = X(:,1);
            X2 = X(:,2);
            Costo = (4 - 2.1*X1.^2 + ((X1.^4) / 3)) .* X1.^2 + X1.*X2 + (-4 + 4*X2.^2).*X2.^2;
            
            Minimo = [ 0.0898 -0.7126;
                      -0.0898  0.7126];
            varargout{1} = Minimo;
            
        % Styblinski-Tang Function
        case {"Styblinski-Tang", "Styblinski"}
            
            Costo = 0.5 * sum(X.^4 - 16*X.^2 + 5*X, 2);
            
            % Mínimo: Vector de -2.903534 con tantas dimensiones como X
            Minimo = -2.903534 * ones(1,size(X,2));
            varargout{1} = Minimo;
            
        case "Easom"
            
            % Error en caso se alimenten coordenadas de más de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La función de costo" + FunctionName + "únicamente acepta coordenadas bidimensionales"); 
            end
            
            X1 = X(:,1);
            X2 = X(:,2); 
            Costo = -cos(X1).*cos(X2).*exp(-(X1 - pi).^2 - (X2 - pi).^2);
            
            Minimo = [pi pi];
            varargout{1} = Minimo;
        
        % Michalewicz Function
        % Fuente: https://www.sfu.ca/~ssurjano/michal.html
        case "Michalewicz"
            
            % Error en caso se alimenten coordenadas de más de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: Función soporta dimensiones arriba de 2, pero se desconocen las coordenadas de estos puntos"); 
            end
            
            % Matriz con el número de columna correspondiente a cada
            % elemento
            i = repmat(1:size(X,2), size(X,1),1);
            
            % Valor recomendado de parámetro: 10
            m = ConstanteM;
            
            Costo = - sum(sin(X).*(sin((i.*X.^2)/pi)).^(2*m), 2);
            
            Minimo = [2.2 1.57];
            varargout{1} = Minimo;
            
            
        % Función basada en paper publicado por Jabandzic y Velagic (2016)
        case "Jabandzic"
                       
            persistent f2
            
            % Vertices de los obstáculos. Se colocan las coordenadas X
            % en la primera columna y las Y en la segunda columna.
            VerticesObs = [VerticesObsX VerticesObsY];
            
            % Vértices del polígono cuadrado que forma el borde la mesa
            % Se repite el primer vértice para que la figura cierre. Los
            % vértices de la mesa inician en el vértice inferior izquierdo
            % y luego se listan en sentido anti-horario.
            VerticesMesa = [LimsX(1) LimsX(1) LimsX(2) LimsX(2) LimsX(1) ; ...
                            LimsY(1) LimsY(2) LimsY(2) LimsY(1) LimsY(1)]';
                        
            % Vértices Mesa + Obstáculos
            VerticesAll = [VerticesObs ; NaN NaN; VerticesMesa; NaN NaN]; 
            
            % F1 - Distancia a la meta:
            % Utilizado para minimizar en la medida de lo posible la
            % distancia hasta la meta que se desea alcanzar.
            f1 = hypot(X(:,1) - Meta(1), X(:,2) - Meta(2)); 
            
            % F3 - Distancias a obstáculo previo más cercano:
            % Si "f2" (Distancia a obstáculo actual más cercano) aún no 
            % existe o su número de filas no coincide con el número de filas 
            % del vector X (Coords de partícula) entonces "f3" consistirá 
            % de un vector columna de "1000's" con tantas filas como "X". 
            % De lo contrario se utiliza el valor previo de "f2".
            if isempty(f2) || size(f2,1) ~= size(X,1)
                f3 = ones(size(X,1),1) * 1000;
            else
                f3 = f2;
            end
            
            % F2 - Recíproco de distancia a obstáculo actual más cercano:
            % Utilizado para alejarse lo más posible del obstáculo más
            % cercano (estático) que ha detectado el puck. Se calculan las
            % distancias del robot controlado hasta los obstáculos
            % detectados. Se seleccionan las coordenadas del obstáculo a la
            % menor distancia (XObsMin, YObsMin)
            [~,XObsMin,YObsMin] = getDistPoint2Poly(PuckPosicion(1,1),PuckPosicion(1,2),VerticesAll(:,1),VerticesAll(:,2));
            
            % Luego se maximiza la distancia de las partículas al obstáculo
            % más cercano al robot / Puck.
            f2 = 1 ./ hypot(X(:,1) - XObsMin, X(:,2) - YObsMin); 
            
            % F4 - Recíproco de distancia al robot:
            % Utilizado para alejar al robot de su posición actual a manera
            % de evitar una potencial colisión. 
            f4 = 1 ./ sqrt(sum((X - PuckPosicion(1,:)) .^2, 2)); 
            f4 = 0;
            
            % F5 - Recíproco de distancia a centro de obstáculo dinámico:
            % Utilizado para alejarse lo más posible del centro del
            % obstáculo dinámico que se aproxima al robot. Primero se
            % calculan las coordenadas de un punto meta alejado del
            % obstáculo (MetaAlejadaObs) utilizando las expresiones:
            %   ys = (yc + yd2) / 2
            %   xs = (xc + xd2) / 2
            % Donde el subíndice "c" hace referencia al robot / puck, el
            % subíndice "d2" al obstáculo dinámico y "s" al punto meta.
            MetaAlejadaObs = (ObsMovilPosicion + PuckPosicion(1,:)) / 2; 
            
            % Luego se maximiza la distancia de las partículas al punto
            % meta alejado del obstáculo dinámico.
            f5 = 1 ./ sqrt(sum((X - MetaAlejadaObs(1,:)) .^2, 2)); 
            f5 = 0;
            
            % K1 y K2 - Parámetros de restricción
            % Utilizados para evitar que las partículas se muevan muy lejos
            % de la posición actual del robot (K1) o que ingresen a
            % una zona "prohibida" (K2).
            k1 = 1000;
            k2 = 1000;
            
            % Coeficientes asociados a cada una de las "F's" de la función
            % de costo.
            w1 = 1;
            w2 = 1.5;
            w3 = 1.5;
            w4 = 1.5;
            w5 = 1.5;
            
            % Coeficientes de restricción
            % W6 = 1: Distancia entre partícula y obstáculo < threshold 
            [DistsPartsAObs] = getDistPoint2Poly(X(:,1),X(:,2),VerticesAll(:,1),VerticesAll(:,2));  % Distancia mínima entre cada partícula y los obstáculos.
            ThresholdDistAObs = 0.3;                                                                % Si una partícula está a menos de esta distancia de un obstáculo, su costo incrementa en gran medida.       

            % También se restringen las regiones dentro de las líneas que
            % conforman los obstáculos. Si no se incluye esto, solo se
            % restringiran las regiones alrededor de las líneas que
            % representan un obstáculo y no del obstáculo como tal.
            InObs = inpolygon(X(:,1),X(:,2),VerticesObs(:,1),VerticesObs(:,2));
 
            w6 = (DistsPartsAObs < ThresholdDistAObs) | InObs;                                   	% Si el punto está dentro del threshold o dentro de un obstáculo, se restringe

            % W7 = 1: Distancia entre partícula y robot > threshold
            DistsPartsAPuck = sqrt(sum((X - PuckPosicion(1,:)) .^2, 2)); 
            ThresholdDistAPuck = 1;   
            w7 = DistsPartsAPuck > ThresholdDistAPuck;
            
            % Suma ponderada utilizando todos los coeficientes "w" y
            % sub-funciones "f".
            Costo = f1*w1 + f2*w2 + f3*w3 + f4*w4 + f5*w5 + k1*w6 + k2*w7;
            
        % Función generada utilizando Artificial Potential Fields
        case "APF"    
                        
            persistent Inicializada CoordsMasCosto
            NoDecimales = 1;

            % Si el número de puntos es muy alto, se asume que la función
            % se está inicializando pasándole una matriz de puntos
            % correspondientes al tablero.
            if size(X,1) > 1000
                
                % Vertices de los obstáculos. Se colocan las coordenadas X
                % en la primera columna y las Y en la segunda columna.
                VerticesObs = [VerticesObsX VerticesObsY];

                % Vértices del polígono cuadrado que forma el borde la mesa
                % Se repite el primer vértice para que la figura cierre
                VerticesMesa = [LimsX(1) LimsX(1) LimsX(2) LimsX(2); ...
                                LimsY(1) LimsY(2) LimsY(2) LimsY(1)]';
                
                % Cabe mencionar que los puntos que definen los vértices del polígono
                % tienen 4 decimales. Los puntos de X pueden tener entre 1 a 4 decimales.
                % Si se intenta usar inpolygon con esta diferencia en cifras significativas
                % el sistema encontrará puntos dentro del polígono, pero no en los bordes
                % ya que busca coincidencias idénticas de puntos y para la función un 0.41005
                % es distinto de un 0.41, por ejemplo. Para evitar esto, ambos vectores se
                % redondean a 1 decimal (Valor de "NoDecimales"), el valor mínimo.
                X = round(X, NoDecimales);
                VerticesObs = round(VerticesObs, NoDecimales);
                VerticesMesa = round(VerticesMesa, NoDecimales);

                % Puntos dentro (In) y en el borde (On) de:
                %   - Los obstáculos (Obs)
                %   - Los bordes de la mesa (Mesa)
                [InObs,OnObs] = inpolygon(X(:,1),X(:,2),VerticesObs(:,1),VerticesObs(:,2));
                [InMesa,OnMesa] = inpolygon(X(:,1),X(:,2),VerticesMesa(:,1),VerticesMesa(:,2));

                % Puntos del Mesh que estén en el borde o en el interior
                % de el o los obstáculos.
                PuntosObs = X(OnObs | InObs,:);
                
                % Puntos del Mesh que estén en el borde o en el exterior de
                % la mesa.
                PuntosMesa = X(OnMesa | ~InMesa,:);
                
                % Traspone y luego repite las coordenadas X y Y, tantas veces 
                % como hay filas en "BordesObs". Se repite "hacia abajo".
                MatrizX = repelem(PuntosObs(:,1), 1, size(X,1));              
                MatrizY = repelem(PuntosObs(:,2), 1, size(X,1));

                % A las matrices se les restan los vectores columna con las
                % coordenadas de los bordes
                CambioX = MatrizX - X(:,1)';
                CambioY = MatrizY - X(:,2)';

                % Se calculan las distancias al obstáculo más cercano
                DistsAObs = sqrt(CambioX'.^2 + CambioY'.^2);
                DistsAObs = min(DistsAObs,[],2);
                
                % Se repite el proceso previo pero ahora para los puntos que
                % forman parte de los bordes de la mesa
                MatrizX = repelem(PuntosMesa(:,1), 1, size(X,1));                 
                MatrizY = repelem(PuntosMesa(:,2), 1, size(X,1));
                CambioX = MatrizX - X(:,1)';
                CambioY = MatrizY - X(:,2)';
                DistsAMesa = sqrt(CambioX'.^2 + CambioY'.^2);
                DistsAMesa = min(DistsAMesa,[],2);
                
                switch Modo
                    case "Choset"
                        Eta = 20;
                        Qi = 5;                                                                 % Threshold para ignorar obstáculos lejanos
                        PotRepulsorMesa = 0.5 * Eta * (1./DistsAMesa - 1/Qi) .^2;
                        PotRepulsorObs = 0.5 * Eta * (1./DistsAObs - 1/Qi) .^2 ;
                        
                        % Se determinan las distancias menores al threshold
                        % Qi como las distancias cercanas a los obstáculos.
                        CercaBordesMesa = DistsAMesa <= Qi;
                        CercaObs = DistsAObs <= Qi;
                        
                        % Las distancias cercanas menores a Qi adquieren
                        % una altura muy grande. El resto toman una altura
                        % de 0. 
                        PotRepulsor = PotRepulsorObs .* CercaObs + PotRepulsorMesa .* CercaBordesMesa;
                        
                        % Ecuaciones propuestas por Choset (Pag. 82)
                        Zeta = 5;                                                               % Factor para escalar el efecto de la atracción
                        DStar = 2;                                                              % Threshold de "cercanía" a un obstáculo
                        PotAtractorParabolico = 0.5 * Zeta * sum((X - Meta).^2, 2);
                        PotAtractorConico = DStar * Zeta * sqrt(sum((X - Meta).^2, 2)) - 0.5 * Zeta * DStar^2;
                        
                        % Se determinan las distancias menores al threshold
                        % DStar o D*. Estas son las distancias "cercanas" a
                        % la meta.
                        DistsAMeta = sqrt(sum((X - Meta).^2, 2));
                        CercaMeta = DistsAMeta <= DStar;
                        
                        % Los puntos cercanos utilizan un potencial atractor
                        % parabólico, mientras que los lejanos utlizan uno
                        % cónico.
                        PotAtractor = PotAtractorParabolico .* CercaMeta + PotAtractorConico .* ~CercaMeta;
                        
                    otherwise
                        Co = 500; Lo = 0.2;
                        Cg = 500; Lg = 3;                                               % Distancia de intensidad / Distancia de correlación para migración grupal
                        PotRepulsorMesa = Co * exp(-(DistsAMesa .^2) / Lo^2);
                        PotRepulsorObs = Co * exp(-(DistsAObs .^2) / Lo^2);
                        PotRepulsor = PotRepulsorMesa + PotRepulsorObs;

                        PotAtractor = Cg * (1 - exp(-(vecnorm(X - Meta).^2) / Lg^2));
                end

                switch Comportamiento
                    case "Multiplicativo"
                        if strcmp(Modo,"Choset")
                            PotTotal = PotRepulsor .* PotAtractor + PotAtractor;
                        else
                            PotTotal = PotRepulsor / Cg .* PotAtractor + PotAtractor;
                        end
                        
                    case "Aditivo"
                        PotTotal = PotRepulsor + PotAtractor;
                end
                
                Inicializada = 1;
                Costo = PotTotal;
                CoordsMasCosto = [X PotTotal];
                disp("Artificial Potential Field inicializado exitosamente");
                
            % Si la función se inicializó previamente y el número de filas
            % de X (Puntos a analizar) es pequeño (Menor a 1000);
            elseif (size(X,1) < 1000 || Inicializada == 1)

                % Se acotan las aproximaciones de las coordenadas X para
                % que al momento de aproximar no se generen valores por
                % encima o por debajo de los límites superiores o
                % inferiores las coordenadas en "CoordsMasCosto".
                X = min(X,max(CoordsMasCosto(:,1:2)));
                X = max(X,min(CoordsMasCosto(:,1:2)));
                                 
                % Se convierten las posiciones dadas en double en caso se
                % requiera.
                X = double(X);

                % Se aproximan las coordenadas de X a la misma cantidad de
                % decimales que las coordenadas en CoordsMasCosto
                X = round(X,NoDecimales);  
                
                % Se buscan coincidencias entre las coordenadas de
                % "CoordsMasCosto" y X. Los índices de CoordsMasCosto donde
                % existe coincidencia se guardan en CoincidenciaFilas
                [~,CoincidenciaFilas] = ismember(X,CoordsMasCosto(:,1:2),'rows');
                
                % Función alternativa al método de indexar utilizando
                % "ismember". Esta función siempre funcionará y nunca
                % retornará errores. A pesar de esto, es un poco más lenta. 
                % Debido a esto solo se incluye aquí pero no se descomenta.
                % CoincidenciaFilas = dsearchn(CoordsMasCosto(:,1:2),X);
                
                % Si no se encuentra alguno de los puntos en X, dentro de
                % "CoordsMasCosto" (Se retorna un índice igual a 0) se
                % despliega un error.
                if any(CoincidenciaFilas == 0)
                    error("Error: No se encontró una coincidencia para el costo de todas las posiciones X dadas por el usuario");
                else
                    Costo = CoordsMasCosto(CoincidenciaFilas,3);
                end

            else
                error("Error. No se inicializó el artificial potential field. Si se desea inicializar, llamar a la función pasándole un vector X con más de 1000 parejas de puntos (X,Y)");
            end
            
            
    end

% NOTA: En caso se deseen agregar más funciones, simplemente se debe agregar
% un "case" adicional y operar tomando en cuenta la forma de X. Porfavor
% implementar las operaciones de manera matricial (Evitando "for loops")
% para no dañar la eficiencia del programa.

end

