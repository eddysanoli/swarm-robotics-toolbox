function [Costo, varargout] = CostFunction(X, FunctionName, varargin)
% COSTFUNCTION Evaluaci�n de las posiciones de las part�culas (X) en
% la funci�n de costo elegida. 
% -------------------------------------------------------------------------
% Inputs:
%   - X: Matriz (Nx2). Cada fila corresponde a las coordenadas de una
%     part�cula. La fila 1 corresponde a la coordenada X y la fila 2
%     corresponde a la coordenada Y.
%   - FunctionName: Funci�n de costo en la que se evaluar�n las
%     coordenadas presentes en la matriz X. 9 opciones en total. 
%
% Inputs Opcionales: 
%   FunctionName = "APF"
%   1. LimsX: L�mites de la mesa de trabajo en X.
%   2. LimsY: L�mites de la mesa de trabajo en Y.
%   3. Meta: Punto a alcanzar por los robots
%
%   FunctionName = "Jabandzic"
%   1. LimsX: L�mites de la mesa de trabajo en X.
%   2. LimsY: L�mites de la mesa de trabajo en Y.
%   3. Meta: Punto a alcanzar por los robots
%   4. PuckPosicion: Posici�n actual del robot siguiendo el swarm de
%      part�culas PSO.
%   5. ObsMovilPosicion: Posici�n actual del obst�culo movil m�s cercano al 
%      robot.
%
% Outputs:
%   - Costo: Vector columna con cada fila consistiendo del costo
%     correspondiente a cada una de las part�culas en el swarm.
%
% -------------------------------------------------------------------------
%
% Par�metros:
% 
%   FunctionName = "Dropwave" 
%   - 'NoWaves': Esta funci�n es similar al patr�n que se observar�a al
%     dejar caer una gota en el agua. El n�mero de "ripples" u olas de la
%     funci�n est� dado por este par�metro. Default = 2;
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
%     Eberhart para evaluar la capacidad de exploraci�n del PSO debido a 
%     las m�ltiples oscilaciones que presenta. Se puede llamar esta funci�n
%     escribiendo tanto "Schaffer F6" como "Schaffer N2". M�nimo = [0,0].
%
%   - Paraboloid / Sphere: Utilizado en la investigaci�n de J. Bansal et
%     al. para evaluar el rendimiento del par�metro de inercia (W). �til para 
%     evaluar la velocidad de convergencia del enjambre por su simplicidad.
%     M�nimo = [0,0].
%
%   - Rosenbrock / Banana: El m�nimo de esta funci�n se presenta en un
%     angosto valle parab�lico. A pesar que el valle es f�cil de ubicar, el
%     m�nimo com�nmente es dificil de localizar debido a que la pendiente
%     presente en el valle es virtualmente nula. M�nimo = [1,1].
%
%   - Booth: Funci�n simple que puede llegar a describirse como una funci�n
%     "Sphere" descentrada. M�nimo = [0,0]
%
%   - Ackley: Utilizada ampliamente para evaluar susceptibilidad a m�nimos
%     locales. Esto se debe a que esta funci�n posee un m�nimo absoluto en
%     [0,0], pero la regi�n circundante al valle que contiene este m�nimo
%     est� repleta de m�nimos locales. M�nimo = [0,0].
%
%   - Rastrigin: Funci�n con m�ltiples m�nimos locales. Su superficie es
%     irregular pero sus m�nimos locales est�n uniformemente distribuidos.
%     M�nimo = [0,0].
%
%   - Levy N13: Utilizada para evaluar susceptibilidad a m�nimos locales.
%     M�nimo = [1,1].
%
%   - Dropwave: Muy similar a la funci�n "SchafferF6". Similar al forma del
%     agua luego que una gota golpeara su superficie. PAR�METRO OPCIONAL DE
%     FUNCI�N: No. de "olas" de la funci�n. 1 M�nimo = [0,0].
%
%   - Himmelblau: Funci�n con m�ltiples m�nimos globales o absolutos. �til
%     para determinar la influencia de la posici�n inicial de las part�culas
%     sobre la decisi�n del punto de convergencia final. 4 M�nimos.
%
%   - APF: Funci�n creada utilizando artificial potential fields. Esta
%     genera un campo de potencial o funci�n de costo "custom" que presenta
%     un valle en la meta a alcanzar y monta�as de altura casi infinita en
%     donde se presentan obst�culos. Si se permite que un algoritmo de
%     optimizaci�n basado en exploraci�n encuentre el m�nimo de esta
%     funci�n, lo m�s com�n es que este navegue alrededor de los obst�culos
%     (Para evitar m�ximos) movi�ndose hacia la meta, donde se encontrar�a
%     el m�nimo.
%
%   - Jabandzic: Funci�n de costo que mezcla las ideas del PSO y
%     planificaci�n de trayectorias. El algoritmo utiliza un plantamiento
%     muy intuitivo: El robot busca maximizar la distancia hacia paredes y
%     obst�culos, mientras minimiza la distancia hacia la meta. Para
%     poder hacer esta minimizaci�n y maximizaci�n, emplea PSO como m�todo
%     para resolver el problema de optimizaci�n.
%
% ------------------------------------------------------------------
    
    % Valores default para inputs
    defaultModoAPF = "Choset";
    defaultComportamientoAPF = "Aditivo";
    defaultNoWaves = 2;
    
    % Se crea el objeto encargado de "parsear" los inputs
    IP = inputParser;  
    
    % Inputs Obligatorios / Requeridos: Necesarios para el funcionamiento 
    % del programa. La funci�n da error si el usuario no los pasa.                                                     
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
    
    % Par�metros: Similar a cuando se utiliza 'FontSize' en plots. El
    % usuario debe escribir el nombre del par�metro a modificar seguido
    % de su valor. Si no se provee un valor Matlab asume uno "default".
    IP.addParameter('ModoAPF', defaultModoAPF, @isstring);
    IP.addParameter('ComportamientoAPF', defaultComportamientoAPF, @isstring);
    IP.addParameter('NoWaves', defaultNoWaves, @isnumeric);
    IP.addParameter('ConstanteM', 10, @isnumeric);
    IP.parse(X,FunctionName,varargin{:});
    
    % Se guardan los inputs "parseados" en variables �tiles capaces
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
            
            % M�nimo: Vector de zeros con tantas dimensiones como X
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
            
            % M�nimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;
            
        % Ackley Function
        % Fuente: https://www.sfu.ca/~ssurjano/ackley.html
        case "Ackley"                      
            a = 20; b = 0.2; c = 2*pi; d = size(X,2);              
            Sum1 = -b * sqrt((1/d) * sum(X.^2, 2));
            Sum2 = (1/d) * sum(cos(c*X), 2);
            Costo = -a*exp(Sum1) - exp(Sum2) + a + exp(1);
            
            % M�nimo: Vector de zeros con tantas dimensiones como X
            Minimo = zeros(1,size(X,2));
            varargout{1} = Minimo;

        % Rastrigin Function
        % Fuente: https://www.sfu.ca/~ssurjano/rastr.html
        case "Rastrigin"
            d = size(X,2);                                          
            Costo = 10*d + sum(X.^2 - 10*cos(2*pi*X), 2);
            
            % M�nimo: Vector de zeros con tantas dimensiones como X
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
            
            % M�nimo: Vector de zeros con tantas dimensiones como X
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
            
            % Error en caso se alimenten coordenadas de m�s de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La funci�n de costo" + FunctionName + "�nicamente acepta coordenadas bidimensionales"); 
            end
            
            Costo = sum(100*(X(:,2)-X(:,1).^2).^2 + (X(:,1)-1).^2, 2);
            
            Minimo = [1 1];
            varargout{1} = Minimo;
        
        % Booth Function
        case "Booth"
            
            % Error en caso se alimenten coordenadas de m�s de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La funci�n de costo" + FunctionName + "�nicamente acepta coordenadas bidimensionales"); 
            end
            
            Costo = (X(:,1) + 2*X(:,2) - 7).^2 + (2*X(:,1) + X(:,2) - 5).^2;
            
            Minimo = [1 3];
            varargout{1} = Minimo;
        
        % Himmelblau Function
        case "Himmelblau"
            
            % Error en caso se alimenten coordenadas de m�s de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La funci�n de costo" + FunctionName + "�nicamente acepta coordenadas bidimensionales"); 
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
               error("Error: La funci�n de costo" + FunctionName + "�nicamente acepta coordenadas bidimensionales"); 
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
            
            % M�nimo: Vector de -2.903534 con tantas dimensiones como X
            Minimo = -2.903534 * ones(1,size(X,2));
            varargout{1} = Minimo;
            
        case "Easom"
            
            % Error en caso se alimenten coordenadas de m�s de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: La funci�n de costo" + FunctionName + "�nicamente acepta coordenadas bidimensionales"); 
            end
            
            X1 = X(:,1);
            X2 = X(:,2); 
            Costo = -cos(X1).*cos(X2).*exp(-(X1 - pi).^2 - (X2 - pi).^2);
            
            Minimo = [pi pi];
            varargout{1} = Minimo;
        
        % Michalewicz Function
        % Fuente: https://www.sfu.ca/~ssurjano/michal.html
        case "Michalewicz"
            
            % Error en caso se alimenten coordenadas de m�s de 2
            % dimensiones
            if size(X,2) > 2
               error("Error: Funci�n soporta dimensiones arriba de 2, pero se desconocen las coordenadas de estos puntos"); 
            end
            
            % Matriz con el n�mero de columna correspondiente a cada
            % elemento
            i = repmat(1:size(X,2), size(X,1),1);
            
            % Valor recomendado de par�metro: 10
            m = ConstanteM;
            
            Costo = - sum(sin(X).*(sin((i.*X.^2)/pi)).^(2*m), 2);
            
            Minimo = [2.2 1.57];
            varargout{1} = Minimo;
            
            
        % Funci�n basada en paper publicado por Jabandzic y Velagic (2016)
        case "Jabandzic"
                       
            persistent f2
            
            % Vertices de los obst�culos. Se colocan las coordenadas X
            % en la primera columna y las Y en la segunda columna.
            VerticesObs = [VerticesObsX VerticesObsY];
            
            % V�rtices del pol�gono cuadrado que forma el borde la mesa
            % Se repite el primer v�rtice para que la figura cierre. Los
            % v�rtices de la mesa inician en el v�rtice inferior izquierdo
            % y luego se listan en sentido anti-horario.
            VerticesMesa = [LimsX(1) LimsX(1) LimsX(2) LimsX(2) LimsX(1) ; ...
                            LimsY(1) LimsY(2) LimsY(2) LimsY(1) LimsY(1)]';
                        
            % V�rtices Mesa + Obst�culos
            VerticesAll = [VerticesObs ; NaN NaN; VerticesMesa; NaN NaN]; 
            
            % F1 - Distancia a la meta:
            % Utilizado para minimizar en la medida de lo posible la
            % distancia hasta la meta que se desea alcanzar.
            f1 = hypot(X(:,1) - Meta(1), X(:,2) - Meta(2)); 
            
            % F3 - Distancias a obst�culo previo m�s cercano:
            % Si "f2" (Distancia a obst�culo actual m�s cercano) a�n no 
            % existe o su n�mero de filas no coincide con el n�mero de filas 
            % del vector X (Coords de part�cula) entonces "f3" consistir� 
            % de un vector columna de "1000's" con tantas filas como "X". 
            % De lo contrario se utiliza el valor previo de "f2".
            if isempty(f2) || size(f2,1) ~= size(X,1)
                f3 = ones(size(X,1),1) * 1000;
            else
                f3 = f2;
            end
            
            % F2 - Rec�proco de distancia a obst�culo actual m�s cercano:
            % Utilizado para alejarse lo m�s posible del obst�culo m�s
            % cercano (est�tico) que ha detectado el puck. Se calculan las
            % distancias del robot controlado hasta los obst�culos
            % detectados. Se seleccionan las coordenadas del obst�culo a la
            % menor distancia (XObsMin, YObsMin)
            [~,XObsMin,YObsMin] = getDistPoint2Poly(PuckPosicion(1,1),PuckPosicion(1,2),VerticesAll(:,1),VerticesAll(:,2));
            
            % Luego se maximiza la distancia de las part�culas al obst�culo
            % m�s cercano al robot / Puck.
            f2 = 1 ./ hypot(X(:,1) - XObsMin, X(:,2) - YObsMin); 
            
            % F4 - Rec�proco de distancia al robot:
            % Utilizado para alejar al robot de su posici�n actual a manera
            % de evitar una potencial colisi�n. 
            f4 = 1 ./ sqrt(sum((X - PuckPosicion(1,:)) .^2, 2)); 
            f4 = 0;
            
            % F5 - Rec�proco de distancia a centro de obst�culo din�mico:
            % Utilizado para alejarse lo m�s posible del centro del
            % obst�culo din�mico que se aproxima al robot. Primero se
            % calculan las coordenadas de un punto meta alejado del
            % obst�culo (MetaAlejadaObs) utilizando las expresiones:
            %   ys = (yc + yd2) / 2
            %   xs = (xc + xd2) / 2
            % Donde el sub�ndice "c" hace referencia al robot / puck, el
            % sub�ndice "d2" al obst�culo din�mico y "s" al punto meta.
            MetaAlejadaObs = (ObsMovilPosicion + PuckPosicion(1,:)) / 2; 
            
            % Luego se maximiza la distancia de las part�culas al punto
            % meta alejado del obst�culo din�mico.
            f5 = 1 ./ sqrt(sum((X - MetaAlejadaObs(1,:)) .^2, 2)); 
            f5 = 0;
            
            % K1 y K2 - Par�metros de restricci�n
            % Utilizados para evitar que las part�culas se muevan muy lejos
            % de la posici�n actual del robot (K1) o que ingresen a
            % una zona "prohibida" (K2).
            k1 = 1000;
            k2 = 1000;
            
            % Coeficientes asociados a cada una de las "F's" de la funci�n
            % de costo.
            w1 = 1;
            w2 = 1.5;
            w3 = 1.5;
            w4 = 1.5;
            w5 = 1.5;
            
            % Coeficientes de restricci�n
            % W6 = 1: Distancia entre part�cula y obst�culo < threshold 
            [DistsPartsAObs] = getDistPoint2Poly(X(:,1),X(:,2),VerticesAll(:,1),VerticesAll(:,2));  % Distancia m�nima entre cada part�cula y los obst�culos.
            ThresholdDistAObs = 0.3;                                                                % Si una part�cula est� a menos de esta distancia de un obst�culo, su costo incrementa en gran medida.       

            % Tambi�n se restringen las regiones dentro de las l�neas que
            % conforman los obst�culos. Si no se incluye esto, solo se
            % restringiran las regiones alrededor de las l�neas que
            % representan un obst�culo y no del obst�culo como tal.
            InObs = inpolygon(X(:,1),X(:,2),VerticesObs(:,1),VerticesObs(:,2));
 
            w6 = (DistsPartsAObs < ThresholdDistAObs) | InObs;                                   	% Si el punto est� dentro del threshold o dentro de un obst�culo, se restringe

            % W7 = 1: Distancia entre part�cula y robot > threshold
            DistsPartsAPuck = sqrt(sum((X - PuckPosicion(1,:)) .^2, 2)); 
            ThresholdDistAPuck = 1;   
            w7 = DistsPartsAPuck > ThresholdDistAPuck;
            
            % Suma ponderada utilizando todos los coeficientes "w" y
            % sub-funciones "f".
            Costo = f1*w1 + f2*w2 + f3*w3 + f4*w4 + f5*w5 + k1*w6 + k2*w7;
            
        % Funci�n generada utilizando Artificial Potential Fields
        case "APF"    
                        
            persistent Inicializada CoordsMasCosto
            NoDecimales = 1;

            % Si el n�mero de puntos es muy alto, se asume que la funci�n
            % se est� inicializando pas�ndole una matriz de puntos
            % correspondientes al tablero.
            if size(X,1) > 1000
                
                % Vertices de los obst�culos. Se colocan las coordenadas X
                % en la primera columna y las Y en la segunda columna.
                VerticesObs = [VerticesObsX VerticesObsY];

                % V�rtices del pol�gono cuadrado que forma el borde la mesa
                % Se repite el primer v�rtice para que la figura cierre
                VerticesMesa = [LimsX(1) LimsX(1) LimsX(2) LimsX(2); ...
                                LimsY(1) LimsY(2) LimsY(2) LimsY(1)]';
                
                % Cabe mencionar que los puntos que definen los v�rtices del pol�gono
                % tienen 4 decimales. Los puntos de X pueden tener entre 1 a 4 decimales.
                % Si se intenta usar inpolygon con esta diferencia en cifras significativas
                % el sistema encontrar� puntos dentro del pol�gono, pero no en los bordes
                % ya que busca coincidencias id�nticas de puntos y para la funci�n un 0.41005
                % es distinto de un 0.41, por ejemplo. Para evitar esto, ambos vectores se
                % redondean a 1 decimal (Valor de "NoDecimales"), el valor m�nimo.
                X = round(X, NoDecimales);
                VerticesObs = round(VerticesObs, NoDecimales);
                VerticesMesa = round(VerticesMesa, NoDecimales);

                % Puntos dentro (In) y en el borde (On) de:
                %   - Los obst�culos (Obs)
                %   - Los bordes de la mesa (Mesa)
                [InObs,OnObs] = inpolygon(X(:,1),X(:,2),VerticesObs(:,1),VerticesObs(:,2));
                [InMesa,OnMesa] = inpolygon(X(:,1),X(:,2),VerticesMesa(:,1),VerticesMesa(:,2));

                % Puntos del Mesh que est�n en el borde o en el interior
                % de el o los obst�culos.
                PuntosObs = X(OnObs | InObs,:);
                
                % Puntos del Mesh que est�n en el borde o en el exterior de
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

                % Se calculan las distancias al obst�culo m�s cercano
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
                        Qi = 5;                                                                 % Threshold para ignorar obst�culos lejanos
                        PotRepulsorMesa = 0.5 * Eta * (1./DistsAMesa - 1/Qi) .^2;
                        PotRepulsorObs = 0.5 * Eta * (1./DistsAObs - 1/Qi) .^2 ;
                        
                        % Se determinan las distancias menores al threshold
                        % Qi como las distancias cercanas a los obst�culos.
                        CercaBordesMesa = DistsAMesa <= Qi;
                        CercaObs = DistsAObs <= Qi;
                        
                        % Las distancias cercanas menores a Qi adquieren
                        % una altura muy grande. El resto toman una altura
                        % de 0. 
                        PotRepulsor = PotRepulsorObs .* CercaObs + PotRepulsorMesa .* CercaBordesMesa;
                        
                        % Ecuaciones propuestas por Choset (Pag. 82)
                        Zeta = 5;                                                               % Factor para escalar el efecto de la atracci�n
                        DStar = 2;                                                              % Threshold de "cercan�a" a un obst�culo
                        PotAtractorParabolico = 0.5 * Zeta * sum((X - Meta).^2, 2);
                        PotAtractorConico = DStar * Zeta * sqrt(sum((X - Meta).^2, 2)) - 0.5 * Zeta * DStar^2;
                        
                        % Se determinan las distancias menores al threshold
                        % DStar o D*. Estas son las distancias "cercanas" a
                        % la meta.
                        DistsAMeta = sqrt(sum((X - Meta).^2, 2));
                        CercaMeta = DistsAMeta <= DStar;
                        
                        % Los puntos cercanos utilizan un potencial atractor
                        % parab�lico, mientras que los lejanos utlizan uno
                        % c�nico.
                        PotAtractor = PotAtractorParabolico .* CercaMeta + PotAtractorConico .* ~CercaMeta;
                        
                    otherwise
                        Co = 500; Lo = 0.2;
                        Cg = 500; Lg = 3;                                               % Distancia de intensidad / Distancia de correlaci�n para migraci�n grupal
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
                
            % Si la funci�n se inicializ� previamente y el n�mero de filas
            % de X (Puntos a analizar) es peque�o (Menor a 1000);
            elseif (size(X,1) < 1000 || Inicializada == 1)

                % Se acotan las aproximaciones de las coordenadas X para
                % que al momento de aproximar no se generen valores por
                % encima o por debajo de los l�mites superiores o
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
                % "CoordsMasCosto" y X. Los �ndices de CoordsMasCosto donde
                % existe coincidencia se guardan en CoincidenciaFilas
                [~,CoincidenciaFilas] = ismember(X,CoordsMasCosto(:,1:2),'rows');
                
                % Funci�n alternativa al m�todo de indexar utilizando
                % "ismember". Esta funci�n siempre funcionar� y nunca
                % retornar� errores. A pesar de esto, es un poco m�s lenta. 
                % Debido a esto solo se incluye aqu� pero no se descomenta.
                % CoincidenciaFilas = dsearchn(CoordsMasCosto(:,1:2),X);
                
                % Si no se encuentra alguno de los puntos en X, dentro de
                % "CoordsMasCosto" (Se retorna un �ndice igual a 0) se
                % despliega un error.
                if any(CoincidenciaFilas == 0)
                    error("Error: No se encontr� una coincidencia para el costo de todas las posiciones X dadas por el usuario");
                else
                    Costo = CoordsMasCosto(CoincidenciaFilas,3);
                end

            else
                error("Error. No se inicializ� el artificial potential field. Si se desea inicializar, llamar a la funci�n pas�ndole un vector X con m�s de 1000 parejas de puntos (X,Y)");
            end
            
            
    end

% NOTA: En caso se deseen agregar m�s funciones, simplemente se debe agregar
% un "case" adicional y operar tomando en cuenta la forma de X. Porfavor
% implementar las operaciones de manera matricial (Evitando "for loops")
% para no da�ar la eficiencia del programa.

end

