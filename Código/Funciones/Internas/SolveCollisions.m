function [Posicion_Actual] = SolveCollisions(Posicion_Actual, RadioPuck)
% SOLVECOLLISIONS Función que toma las posiciones actuales de las
% partículas, chequea si alguna pareja de partículas está a menos de 1
% diámetro de distancia entre si, y corrige su posición de manera acorde.
% -------------------------------------------------------------------------

DistsEntrePart = getDistsBetweenParticles(Posicion_Actual,"Triangular");       	% Escribir "help getDistsBetweenParticles" para más información
[ColidingPartMain, ColidingPartAux] = find(DistsEntrePart < 2*RadioPuck);       % Se obtiene el "index" de los pucks sobrepuestos. Los valores NaN se ignoran.
ColidingPart = [ColidingPartMain ColidingPartAux];                              % Se unen los ID's de los "Main" pucks (Filas con colisiones) y "Aux" pucks (Columnas).
HayColisiones = ~isempty(ColidingPart);                                         % Se chequea si el vector con partículas en colisión está vacío 

Iteraciones = 0;
IteracionesMax = 40;                                                            % 20 parece ser el número de iteraciones que genera los resultados más saisfactorios.

while HayColisiones && (Iteraciones < IteracionesMax)
    
    % Componentes X y Y del vector que conecta el centro de "Main" y
    % "Aux". Luego se obtiene el ángulo de inclinación de dicho vector
    VecColidingPart = Posicion_Actual(ColidingPartMain,:) - Posicion_Actual(ColidingPartAux,:);
    AngColidingPart = atan(VecColidingPart(:,2) ./ VecColidingPart(:,1)); 

    % Si el ángulo es negativo, se convierte en positivo
    % Si el ángulo > pi/2 se hace (pi - ángulo) para obtener un valor entre 0 y pi/2
    AngColidingPart = abs(AngColidingPart); 
    AngColidingPart(AngColidingPart > pi/2) = pi - AngColidingPart(AngColidingPart > pi/2);

    % No se pueden tomar los valores "ColidingPart[Main/Aux]" para indexar
    % directamente la matrix cuadrada "DistsEntrePart". Para lograr esto
    % primero se convierte a "DistsEntrePart" en un vector columna. Luego
    % se usa sub2ind() para transformar las "filas" y "columnas" extraidas
    % en "ColidingPart[Main/Aux]" (Main = Fila / Aux = Columna) en un índice
    % para la versión lineal de "DistsEntrePart".
    LinearIndex = sub2ind(size(DistsEntrePart), ColidingPartMain, ColidingPartAux);

    ExcessDist = 2*RadioPuck - DistsEntrePart(LinearIndex);                     % "Overlap" que existe entre partículas: Diametro Puck - Distancia Actual Entre Particulas
    DistAjusteX = (ExcessDist/2) .* cos(AngColidingPart);                       % Distancia que se deben mover las partículas en X para moverse a una posición "sin colisión"
    DistAjusteY = (ExcessDist/2) .* sin(AngColidingPart);                       % Distancia que se deben mover las partículas en Y para moverse a una posición "sin colisión"  
    DistAjusteX = repelem(DistAjusteX, 1, 2);                                   % El vector columna "DistAjusteX" se repite 1 vez más hacia la derecha. Dims: "No Colisiones" x 2
    DistAjusteY = repelem(DistAjusteY, 1, 2);                                   % El vector columna "DistAjusteY" se repite 1 vez más hacia la derecha. Dims: "No Colisiones" x 2

    % Se comparan las coordenadas X de los "Main" y "Aux" pucks. Se
    % determina cual de los dos es el que posee la coordenada X más 
    % grande (Partícula más a la derecha / PartMasDerecha).
    [~, ColPartMasDerecha] = max([Posicion_Actual(ColidingPartMain,1) Posicion_Actual(ColidingPartAux,1)], [], 2);
    IndexPartMasDerecha = sub2ind(size(ColidingPart), (1:size(ColidingPart,1))', ColPartMasDerecha);
    PartMasDerecha = ColidingPart(IndexPartMasDerecha);

    % Se repite el mismo proceso anterior, pero para las coordenadas Y
    % del "Main" y "Aux" pucks.
    [~, ColPartMasArriba] = max([Posicion_Actual(ColidingPartMain,2) Posicion_Actual(ColidingPartAux,2)], [], 2);
    IndexPartMasArriba = sub2ind(size(ColidingPart), (1:size(ColidingPart,1))', ColPartMasArriba);
    PartMasArriba = ColidingPart(IndexPartMasArriba);
    
    % Se inicia con una matriz de -1 del tamaño de "ColidingPart". Se
    % asigna un valor de +1 a los índices correspondientes a las partículas
    % más a la derecha ("PartMasDerecha").
    SignoSumaX = -1 * ones(size(ColidingPart));
    SignoSumaX(ColidingPart == PartMasDerecha) = 1;
    
    % Se repite el mismo proceso para los signos de la suma que se le hará
    % a las coordenadas Y de las partículas.
    SignoSumaY = -1 * ones(size(ColidingPart));
    SignoSumaY(ColidingPart == PartMasArriba) = 1;
    
    % Se convierten todos los vectores a continuación en vectores columna
    SignoSumaX = SignoSumaX(:);
    SignoSumaY = SignoSumaY(:);
    ColidingPart = ColidingPart(:);
    DistAjusteX = DistAjusteX(:);
    DistAjusteY = DistAjusteY(:);
    
    % Actualización de las coordenadas X y Y
    Posicion_Actual(ColidingPart,1) = Posicion_Actual(ColidingPart,1) + (DistAjusteX .* SignoSumaX);
    Posicion_Actual(ColidingPart,2) = Posicion_Actual(ColidingPart,2) + (DistAjusteY .* SignoSumaY);
    
    DistsEntrePart = getDistsBetweenParticles(Posicion_Actual,"Triangular");        % Se re-obtienen las distancias entre partículas luego de la primera corrección.
    [ColidingPartMain, ColidingPartAux] = find(DistsEntrePart < 2*RadioPuck);       % Se obtiene el "index" de los pucks sobrepuestos. Los valores NaN se ignoran.
    ColidingPart = [ColidingPartMain ColidingPartAux];                              % Se unen los ID's de los "Main" pucks (Filas con colisiones) y "Aux" pucks (Columnas).
    HayColisiones = ~isempty(ColidingPart);                                         % Se re-evalúa si no hay colisiones.
    
    Iteraciones = Iteraciones + 1;
    
end

end

