%% ==========================
% GENERACIÓN DE DATASET
% ===========================

% Se limpian las variables del workspace, incluyendo las variables
% persistentes presentes dentro de las diferentes funciones empleadas.
clear;
clear ComputeInertia;                               % Se limpian las variables persistentes dentro de "ComputeInertia.m"
clear CostFunction;                                 % Se limpian las variables persistentes dentro de "CostFunction.m"
clear getCriteriosConvergencia;                     % Se limpia la posición previa de entidad dentro de "getCriteriosConvergencia.m"

% Parámetros generales
NoParts = 1000;
IterMaxPSO = 200;
Runs = 20;
NormalizarData = 0;

% Tipo de dataset a generar: "Train" o "Test"
% Nada cambia al alterar este parámetro, solo el nombre con el que se
% guardará la data generada.
TipoDataset = "Test";          

% Creación de barra de progreso
ProgressBar = waitbar(0,'Corriendo Pruebas PSO...');

% Dims Mesa
AnchoMesa = 20;                                     
AltoMesa = 20;
Margen = 0.4;
LimsX = [-AnchoMesa/2 AnchoMesa/2]';                
LimsY = [-AltoMesa/2 AltoMesa/2]';      

% Listas de parámetros
FuncionesCosto = ["Banana" "Dropwave" "Levy" "Himmelblau" "Rastrigin" "Schaffer F6" "Sphere" "Booth" "Ackley" "APF" "Griewank"];
Restricciones = ["Mixto" "Inercia" "Constriccion"];
TiposInercia = ["Constant" "Linear" "Chaotic" "Random" "Exponent1"];
 
% Número de muestras totales
NoMuestras = numel(FuncionesCosto) * Runs * ((numel(Restricciones)-1) + numel(TiposInercia));
MuestrasObtenidas = 0;

% Creación de celdas
NetInput = cell(NoMuestras,1);
NetOutput = cell(NoMuestras,1);
DetallesRuns = cell(NoMuestras,1);

% Un set de "runs" por cada función de costo
for n = 1:numel(FuncionesCosto)
    
    FuncCosto_Actual = FuncionesCosto(n);
    
    % Función benchmark?
    FuncionesBenchmark = ["Banana" "Dropwave" "Levy" "Himmelblau" "Rastrigin" "Schaffer F6" "Sphere" "Booth" "Ackley" "Griewank"];
    if contains(FuncCosto_Actual,FuncionesBenchmark)
        isBenchmark = 1;
    else
        isBenchmark = 0;
    end
    
    % Si la función de costo elegida es de tipo APF, se define el
    % obstáculo asociado a la mesa de trabajo de forma aleatoria.
    if strcmp(FuncCosto_Actual,"APF")
        
        % Se elige un obstáculo de forma aleatoria
        IndObs = randi([1 4]);
        Obstaculos = ["Cilindro" "Caso A" "Caso B" "Caso C"];
        Obstaculo_Actual = Obstaculos(IndObs);
        
        RadioObstaculo = 1;                                                     
        AlturaObstaculo = 1;
        OffsetObstaculo = 0;
        Meta = [-3 3];
        
        switch Obstaculo_Actual
            
            case "Cilindro"
                [XObs,YObs,ZObs] = DrawObstacles(Obstaculo_Actual, AlturaObstaculo, OffsetObstaculo, RadioObstaculo);
            
            case "Caso A"
                XObs = [-2 -2 0 0 -2]'; 
                YObs = [-7 7 7 -7 -7]';
                XObs = interp1([-10 10],[LimsX(1) LimsX(2)],XObs);
                YObs = interp1([-10 10],[LimsY(1) LimsY(2)],YObs);
                [XObs,YObs,ZObs] = DrawObstacles("Custom",AlturaObstaculo,OffsetObstaculo,XObs, YObs);
            
            case "Caso B"
                XObs = [ 0 0 2  2  0]'; 
                YObs = [-2 2 2 -2 -2]';
                XObs = interp1([-10 10],[LimsX(1) LimsX(2)],XObs);
                YObs = interp1([-10 10],[LimsY(1) LimsY(2)],YObs);
                [XObs,YObs,ZObs] = DrawObstacles("Custom",AlturaObstaculo,OffsetObstaculo,XObs, YObs);
                
            case "Caso C"
                Meta = [-3 0];
                XObs = [-6 -6 -5 -5 -6 NaN -6 -6 -5 -5 -6 NaN -1 -1 0  0 -1 NaN]';
                YObs = [-5 -4 -4 -5 -5 NaN  5  4  4  5  5 NaN -1  0 0 -1 -1 NaN]';
                XObs = interp1([-10 10],[LimsX(1) LimsX(2)],XObs);
                YObs = interp1([-10 10],[LimsY(1) LimsY(2)],YObs);
                [XObs,YObs,ZObs] = DrawObstacles("Custom",AlturaObstaculo,OffsetObstaculo,XObs, YObs);
        end
        
    end
    
    % Se actualizan los parámetros ambientales
    switch FuncCosto_Actual
        case "APF"
            EnvironmentParams = {XObs(:,1), YObs(:,1), LimsX, LimsY, Meta};
              
        otherwise
            EnvironmentParams = {};
    end
    
    % Se inicializa la función de costo y se establece la meta.
    Resolucion = 0.1;
    [MeshX, MeshY] = meshgrid(LimsX(1)-Margen:Resolucion:LimsX(2)+Margen, LimsY(1)-Margen:Resolucion:LimsY(2)+Margen);
    Mesh2D = [MeshX(:) MeshY(:)];
    
    if isBenchmark
        [~, Meta] = CostFunction(Mesh2D, FuncCosto_Actual, EnvironmentParams{:});
    else
        CostoPart = CostFunction(Mesh2D, FuncCosto_Actual, EnvironmentParams{:});
    end
    
    % Se crea el objeto PSO
    Swarm = PSO(NoParts, 2, FuncCosto_Actual, "Entidades Detenidas", IterMaxPSO, [LimsX' ; LimsY']);
    
    % Un set de "runs" para cada tipo de restricción
    for i = 1:numel(Restricciones)
        
        Restriccion_Actual = Restricciones(i);
        
        % El sweep cambia según el tipo de caso a utilizar.
        switch Restriccion_Actual
            
            case "Inercia"
                
                % Un set de "runs" para cada tipo de inercia disponible
                for j = 1:numel(TiposInercia)
                    
                    Inercia_Actual = TiposInercia(j);
                    
                    % Runs para la combinación de parámetros actual
                    for k = 1:Runs
                    
                        Swarm.InitPSO(EnvironmentParams);
                        Swarm.SetRestricciones(Restriccion_Actual,LimsX,LimsY,'TipoInercia',Inercia_Actual);   
                        
                        Historial_Params = zeros(4,IterMaxPSO);
                        DistAMeta_Norm = zeros(1,IterMaxPSO);
                        CoherenciaSwarm = zeros(1,IterMaxPSO);
                        PromDistPromPartASwarm = zeros(1,IterMaxPSO);
                        
                        % Se corre el PSO.
                        for h = 1:IterMaxPSO
                            [StopPart] = Swarm.RunStandardPSO("Steps", Meta, EnvironmentParams);
                            
                            % En cada iteración se toma nota de la inercia
                            % y las constantes Phi1 y Phi2
                            Historial_Params(1:3,h) = [Swarm.W ; Swarm.Phi1 ; Swarm.Phi2];
                            
                            % Medida de la distancia del global best del swarm a la meta
                            % (Normalizado)
                            IndDistMin = dsearchn(Meta, Swarm.Posicion_GlobalBest);                                             % Indice de la meta más cercana al global best
                            ComponenteXDist = Meta(IndDistMin,1) - Swarm.Posicion_GlobalBest(1);                                % Componente X de la distancia entre meta y global best
                            ComponenteYDist = Meta(IndDistMin,2) - Swarm.Posicion_GlobalBest(2);                                % Componente Y de la distancia entre meta y global best
                            DistMasLejana = hypot(LimsX(2) - abs(Meta(IndDistMin,1)), LimsY(2) - abs(Meta(IndDistMin,2)));      % Distancia más lejana que pueden tomar las partículas a la meta dada la dimensión de la mesa
                            DistAMeta_Norm(i) = hypot(ComponenteXDist, ComponenteYDist) / DistMasLejana;                        % Normalización de componentes y cálculo de distancia entre meta y global best
                            
                            % Promedio de la distancia Promedio de cada Partícula a todo el resto del
                            % Swarm (D_all)
                            MediaSwarm = mean(Swarm.Posicion_Actual);
                            DistsEntrePartsSwarm = getDistsBetweenParticles(Swarm.Posicion_Actual,"Full");
                            DistMasLejana = hypot(LimsX(2) - abs(MediaSwarm(1)), LimsY(2) - abs(MediaSwarm(2)));
                            PromDistPromPartASwarm(i) = mean(DistsEntrePartsSwarm,'all') / DistMasLejana;
                            
                           	% Coherencia de la Swarm
                            VelCentroSwarm = norm(mean(Swarm.Velocidad));                                % Velocidad del centro del swarm (Vs)
                            VelPromedioParts = mean(vecnorm(Swarm.Velocidad,2,2));                       % Velocidad promedio de todas las partículas
                            CoherenciaSwarm(i) = (VelCentroSwarm + 0.01)/ (VelPromedioParts + 0.01);    % Razón entre ambos valores. Ajuste de 0.01, para que cuando ambos tiendan a 0, no den NaN
                            
                            if StopPart                         
                                break;      
                            end
                        end
                        
                        % Se incrementa la cuenta de muestras tomadas hasta
                        % ahora y se actualiza la barra de progreso
                        MuestrasObtenidas = MuestrasObtenidas + 1;
                        waitbar(MuestrasObtenidas / NoMuestras);
                        
                        % Se extraen las iteraciones necesarias para converger
                        IterFinal = Swarm.IteracionActual;
                        
                        % Medida normalizada de la dispersión promedio
                        % correspondiente a la Swarm
                        DesvEstPosX = std(Swarm.Posicion_History{1}) / (AnchoMesa/2);
                        DesvEstPosY = std(Swarm.Posicion_History{2}) / (AltoMesa/2);
                        DesvEstPosMedia = mean([DesvEstPosX; DesvEstPosY]);
                        
                      	% Se da forma al feature vector que tendrá como input la
                        % Neural Net. Este consiste de un vector columna construido
                        % por las siguientes partes
                        % - Fila 1: Desviación estándar promedio normalizada
                        % - Fila 2: Coherencia de la swarm (Velocidad de centro
                        %   dividido velocidad promedio de partículas)
                        % - Fila 3: Distancia a la meta normalizada en función
                        %   de la dimensión del escenario
                        % - Fila 4: Promedio de las distancias promedio
                        %   existentes entre cada partícula y todas sus vecinas
                        FeatureVector = [DesvEstPosMedia(1:IterFinal);
                                         CoherenciaSwarm(1:IterFinal);
                                         DistAMeta_Norm(1:IterFinal);
                                         PromDistPromPartASwarm(1:IterFinal)];
        
                        % Se agrega el feature vector generado como una nueva
                        % muestra o como una nueva fila del array de celdas
                        % "NetInput".
                        NetInput{MuestrasObtenidas} = FeatureVector;
                        
                        % Detalles de la corrida realizada
                        Descripcion = [FuncCosto_Actual;
                                       Restriccion_Actual;
                                       Inercia_Actual;
                                       num2str(Swarm.Wmin);
                                       num2str(Swarm.Wmax);
                                       num2str(Swarm.Phi1);
                                       num2str(Swarm.Phi2)];
                        DetallesRuns{MuestrasObtenidas} = Descripcion;
                        
                        % La cuarta fila del historial de parámetros se iguala
                        % al número total de iteraciones que le tomó al
                        % algoritmo converger.
                        Historial_Params(4,:) = IterFinal / IterMaxPSO;

                        % El response vector se tomará desde la iteración 1
                        % hasta la iteración para convergencia.
                        ResponseVector = Historial_Params(:,1:IterFinal);
                        NetOutput{MuestrasObtenidas} = ResponseVector;
                        
                        
                    end
                end
                
            otherwise
                
                for k = 1:Runs
                    Swarm.InitPSO(EnvironmentParams);
                    Swarm.SetRestricciones(Restriccion_Actual,LimsX,LimsY);   
                    
                    % Se alteran aleatoriamente los parámetros Phi1 y Phi2
                    % para dar variedad al dataset.
                    % Swarm.Phi1 = randi([2 15]);
                    % Swarm.Phi2 = randi([2 15]);
                    
                    Historial_Params = zeros(4,IterMaxPSO);
                    DistAMeta_Norm = zeros(1,IterMaxPSO);
                    CoherenciaSwarm = zeros(1,IterMaxPSO);
                    PromDistPromPartASwarm = zeros(1,IterMaxPSO);
                    
                    % Se corre el PSO.
                    for j = 1:IterMaxPSO
                        [StopPart] = Swarm.RunStandardPSO("Steps", Meta, EnvironmentParams);
                        Historial_Params(1:3,j) = [Swarm.W ; Swarm.Phi1 ; Swarm.Phi2];
                        
                        % Medida de la distancia del global best del swarm a la meta
                        % (Normalizado)
                        IndDistMin = dsearchn(Meta, Swarm.Posicion_GlobalBest);                                          % Indice de la meta más cercana al global best
                        ComponenteXDist = Meta(IndDistMin,1) - Swarm.Posicion_GlobalBest(1);                             % Componente X de la distancia entre meta y global best
                        ComponenteYDist = Meta(IndDistMin,2) - Swarm.Posicion_GlobalBest(2);                             % Componente Y de la distancia entre meta y global best
                        DistMasLejana = hypot(LimsX(2) - abs(Meta(IndDistMin,1)), LimsY(2) - abs(Meta(IndDistMin,2)));  % Distancia más lejana que pueden tomar las partículas a la meta dada la dimensión de la mesa
                        DistAMeta_Norm(i) = hypot(ComponenteXDist, ComponenteYDist) / DistMasLejana;                    % Normalización de componentes y cálculo de distancia entre meta y global best

                        % Promedio de la distancia Promedio de cada Partícula a todo el resto del
                        % Swarm (D_all)
                        MediaSwarm = mean(Swarm.Posicion_Actual);
                        DistsEntrePartsSwarm = getDistsBetweenParticles(Swarm.Posicion_Actual,"Full");
                        DistMasLejana = hypot(LimsX(2) - abs(MediaSwarm(1)), LimsY(2) - abs(MediaSwarm(2)));
                        PromDistPromPartASwarm(i) = mean(DistsEntrePartsSwarm,'all') / DistMasLejana;

                        % Coherencia de la Swarm
                        VelCentroSwarm = norm(mean(Swarm.Velocidad));                                % Velocidad del centro del swarm (Vs)
                        VelPromedioParts = mean(vecnorm(Swarm.Velocidad,2,2));                       % Velocidad promedio de todas las partículas
                        CoherenciaSwarm(i) = (VelCentroSwarm + 0.01)/ (VelPromedioParts + 0.01);    % Razón entre ambos valores. Ajuste de 0.01, para que cuando ambos tiendan a 0, no den NaN

                        if StopPart                         
                            break;      
                        end
                    end
                    
                    % Se incrementa la cuenta de muestras tomadas hasta
                    % ahora y se actualiza la barra de progreso
                    MuestrasObtenidas = MuestrasObtenidas + 1;
                    waitbar(MuestrasObtenidas / NoMuestras);
                        
                    % Se extraen las iteraciones necesarias para converger
                    IterFinal = Swarm.IteracionActual;
                    
                    % Medida normalizada de la dispersión promedio
                    % correspondiente a la Swarm
                    DesvEstPosX = std(Swarm.Posicion_History{1}) / (AnchoMesa/2);
                    DesvEstPosY = std(Swarm.Posicion_History{2}) / (AltoMesa/2);
                    DesvEstPosMedia = mean([DesvEstPosX; DesvEstPosY]);
                        
                    % Se da forma al feature vector que tendrá como input la
                    % Neural Net. Este consiste de un vector columna construido
                    % por las siguientes partes
                    % - Fila 1: Desviación estándar promedio normalizada
                    % - Fila 2: Coherencia de la swarm (Velocidad de centro
                    %   dividido velocidad promedio de partículas)
                    % - Fila 3: Distancia a la meta normalizada en función
                    %   de la dimensión del escenario
                    % - Fila 4: Promedio de las distancias promedio
                    %   existentes entre cada partícula y todas sus vecinas
                    FeatureVector = [DesvEstPosMedia(1:IterFinal);
                                     CoherenciaSwarm(1:IterFinal);
                                     DistAMeta_Norm(1:IterFinal);
                                     PromDistPromPartASwarm(1:IterFinal)];
    
                    % Se agrega el feature vector generado como una nueva
                    % muestra o como una nueva fila del array de celdas
                    % "NetInput".
                    NetInput{MuestrasObtenidas} = FeatureVector;
                    
                    % Detalles de la corrida realizada
                    Descripcion = [FuncCosto_Actual;
                                   Restriccion_Actual;
                                   num2str(Swarm.Wmin);
                                   num2str(Swarm.Wmax);
                                   num2str(Swarm.Phi1);
                                   num2str(Swarm.Phi2)];
                    DetallesRuns{MuestrasObtenidas} = Descripcion;
                    
                    % La cuarta fila del historial de parámetros se iguala
                    % al número total de iteraciones que le tomó al
                    % algoritmo converger.
                    Historial_Params(4,:) = IterFinal / IterMaxPSO;
                    
                    % El response vector se tomará desde la iteración 1
                    % hasta la iteración para convergencia.
                    ResponseVector = Historial_Params(:,1:IterFinal);
                    NetOutput{MuestrasObtenidas} = ResponseVector;
                    
                end
                  
        end
        
    end
    
end

close(ProgressBar);

% Dataset de entrenamiento
if strcmp(TipoDataset,"Train")
    save("Deep PSO Tuner\Datasets\PSO_" + TipoDataset + "Dataset - Output",'NetOutput');
    save("Deep PSO Tuner\Datasets\PSO_" + TipoDataset + "Dataset - Input",'NetInput');
    save("Deep PSO Tuner\Datasets\PSO_" + TipoDataset + "Dataset - Detalles",'DetallesRuns');

% Dataset de validación
else
    TestInput = NetInput;
    TestOutput = NetOutput;
    save("Deep PSO Tuner\Datasets\PSO_" + TipoDataset + "Dataset - Output",'TestOutput');
    save("Deep PSO Tuner\Datasets\PSO_" + TipoDataset + "Dataset - Input",'TestInput');
    save("Deep PSO Tuner\Datasets\PSO_" + TipoDataset + "Dataset - Detalles",'DetallesRuns');
end

%% ==========================
% NORMALIZACIÓN DE LA DATA
% ===========================

if NormalizarData
    
    % Se normaliza la data de entrada para acelerar el proceso de aprendizaje.
    % Dado que en la red neuronal a utilizar se utiliza la función de
    % activación TanH(), entonces el uso de muestras normalizadas es
    % recomendado para acelerar el aprendizaje.
    mu = mean([NetInput{:}],2);
    sig = std([NetInput{:}],0,2);
    
    for i = 1:numel(NetInput)
        NetInput{i} = (NetInput{i} - mu) ./ sig;
    end
    
end


%% ==========================
% PREPARAR LA DATA PARA PADDING
% ===========================

% Las secuencias guardadas en "NetInput" no tienen todas la misma longitud.
% Al dividir la data en "Batches" utilizando el "MiniBatchSize", todas
% estas secuencias se dividirán en bloques. Las secuencias que tengan una 
% menor longitud que el resto se les agregará padding, lo cual puede sesgar
% el entrenamiento. La idea de este paso consiste en dividir la data en
% grupos con longitudes similares para así evitar el agregado innecesario
% de padding.

% Se obtiene el largo de cada secuencia almacenada en el array de celdas.
for i = 1:numel(NetInput)
    Secuencias = NetInput{i};
    LargoSecuencias(i) = size(Secuencias,2);
end

% Graficando un diagrama de barras para los largos de las secuencias
% alimentadas "desordenadas".
figure('Name',"Ordenando Secuencias por Largo", 'Position', [100, 100, 1024, 500]);
subplot(1,2,1); hold on;
bar(LargoSecuencias,'FaceColor',[0 0.4470 0.7410],'BarWidth', 1); 
xlabel("Secuencias")
xlim([0 numel(LargoSecuencias)]);
ylabel("Largo (No. Columnas)")
title("Secuencias Desordenadas")

% Se ordenan los largos de las secuencias en orden descendente (De mayor
% largo a menor largo). Se reordenan también los arrays de Inputs y
% Outputs.
[LargoSecuencias,idx] = sort(LargoSecuencias,'descend');
NetInputSorted = NetInput(idx);
NetOutputSorted = NetOutput(idx);

% Graficando un diagrama de barras para los largos de las secuencias
% alimentadas "ordenadas".
subplot(1,2,2); hold on;
xlabel("Secuencias")
xlim([0 numel(LargoSecuencias)]);
ylabel("Largo (No. Columnas)");
title("Secuencias Ordenadas");

% CAMBIAR. Número de secuencias que se alimentarán de manera simultánea a 
% la red neuronal al momento de entrenarla. Jugar con este valor hasta que
% la cantidad de padding agregado a cada batch sea el menor posible (Hasta
% que casi no se vea color amarillo).
MiniBatchSize = 50;

% Cantidad de grupos (Batches) en los que se dividirá la data al momento de
% alimentarse a la red neuronal.
NoIntervalos = floor(numel(LargoSecuencias) / MiniBatchSize);

% Gráfica de las líneas verticales rojas.
PlotFronteras = 1;
AlturasMax = zeros(1,NoIntervalos);
Divisiones = zeros(1,NoIntervalos);

if PlotFronteras
    for i = 1:NoIntervalos
        Divisiones(i) = MiniBatchSize * i;
        xline(Divisiones(i),'--r','HandleVisibility','off');
        AlturasMax(i) = max(LargoSecuencias((i-1)*MiniBatchSize + 1: i*MiniBatchSize));
    end
end

% Gráfica amarilla de las barras de padding.
Histograma = histogram(1:MiniBatchSize*NoIntervalos,NoIntervalos,'EdgeAlpha',0,'FaceColor',[0.9290 0.6940 0.1250],'BinWidth',MiniBatchSize);
Histograma.BinCounts = AlturasMax;

% Longitudes de secuencias "ordenadas"
bar(LargoSecuencias,'FaceColor',[0 0.4470 0.7410],'BarWidth', 1);
legend("Padding por Batch", "Largo de Secuencias");