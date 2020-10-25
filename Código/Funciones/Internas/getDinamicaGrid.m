function [Recompensa,EstadoFuturo] = getDinamicaGrid(Accion,EstadoActual,MatrizEstados,EstadosMeta,EstadosObs)
% DINAMICAGRID Función que toma el estado en el que se encuentra el agente
% (Su posición en la grid) y la acción que va a tomar y determina el estado
% futuro en el que deberá posicionarse y su recompensa correspondiente.
% -------------------------------------------------------------------------
% Inputs:
%   - Acción: Número de 1 a 8, con cada número representando una dirección
%     de movimiento. 
%
%       1: Arriba           / 2: Abajo 
%       3: Izquierda        / 4: Derecha
%       5: Arriba-izquierda / 6: Arriba-derecha
%       7: Abajo-izquierda  / 8: Abajo-derecha
%
%   - EstadoActual: ID numérico del estado actual en el que se encuentra el
%     agente. Debe consistir de un número de 1 a NoEstados.
%   - MatrizEstados: Matriz rectangular con tantos elementos en su array
%     como celdas existen en la grid. Los valores contenidos en el mismo
%     consisten del ID numérico de cada estado y están ordenados de la
%     misma que en la grid. Por ejemplo, para un grid de 3x3 los estados
%     están ordenados de la siguiente manera:
%
%     	| 1 | 4 | 7 |
%       | 2 | 5 | 8 |
%       | 3 | 6 | 9 |
%
%   - EstadosMeta: ID de los estados o celdas que contienen a él o los
%     puntos meta ubicados dentro del espacio de estados.
%   - EstadosObs: ID de los estados o celdas que contienen obstáculos u
%     objetos que se desean esquivar.
%
% Outputs:
%   - Recompensa: Valor de recompensa o castigo recibido por el agente por
%     realizar la "Accion" mientras se estaba en el "EstadoActual". Valor
%     numérico.
%   - EstadoFuturo: Estado futuro o posición a la que se moverá el agente
%     dado que decidió tomar la "Accion". Por ejemplo, si estaba en un grid
%     de 2x2, y estando en el estado 4 decide moverse hacia arriba, este
%     se moverá al estado 3. 
%
% -------------------------------------------------------------------------    

% Extracción del ancho y alto del Grid
[AltoGrid, AnchoGrid] = size(MatrizEstados);

% Se asume inicialmente que no existirán colisiones
ColisionBorde = 0;
ColisionParcial = 0;

% Se asume que el movimiento no es diagonal
isDiagonal = 0;

% Se extraen las "coordenadas" del estado actual
[FilaActual,ColumnaActual] = find(MatrizEstados == EstadoActual);

% Se calcula el ID de los estados ubicados en cada posición alrededor
% del estado actual (Posiciones cardinales y diagonales).
EstadoArriba    = EstadoActual - 1;
EstadoAbajo     = EstadoActual + 1;
EstadoIzquierda = EstadoActual - AltoGrid;
EstadoDerecha   = EstadoActual + AltoGrid;
EstadoArribaIzq = EstadoActual - (AltoGrid + 1);
EstadoArribaDer = EstadoActual + (AltoGrid - 1);
EstadoAbajoIzq  = EstadoActual - (AltoGrid - 1);
EstadoAbajoDer  = EstadoActual + (AltoGrid + 1);

% ===================================
% Estado futuro 
% ===================================

switch Accion
    % Arriba
    case 1
        EstadoFuturo = EstadoArriba;
        if FilaActual == 1
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar
        end

    % Abajo
    case 2
        EstadoFuturo = EstadoAbajo;
        if FilaActual == AltoGrid
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end

    % Izquierda
    case 3
        EstadoFuturo = EstadoIzquierda;
        if ColumnaActual == 1
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end

    % Derecha
    case 4
        EstadoFuturo = EstadoDerecha;
        if ColumnaActual == AnchoGrid
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end

    % Arriba-izquierda
    case 5
        EstadoFuturo = EstadoArribaIzq;
        if (FilaActual == 1 || ColumnaActual == 1)
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end

        % No puede moverse en diagonal cuando tiene un obstáculo arriba y
        % a la izquierda
        if ismember(EstadoIzquierda,EstadosObs) && ismember(EstadoArriba,EstadosObs)
            ColisionBorde = 1;
            EstadoFuturo = EstadoActual;

        % Si hay un obstáculo a la izquierda y no arriba, al intentar moverse
        % se detecta una "colisión parcial".
        elseif ismember(EstadoIzquierda,EstadosObs) && ~ismember(EstadoArriba,EstadosObs)
            ColisionParcial = 1;

        % Si hay un obstáculo a arriba y no a la izquierda, al intentar moverse
        % se detecta una "colisión parcial".
        elseif ~ismember(EstadoIzquierda,EstadosObs) && ismember(EstadoArriba,EstadosObs)
            ColisionParcial = 1;    
        end
        
        % El agente se mueve en diagonal
        isDiagonal = 1;

    % Arriba-derecha
    case 6
        EstadoFuturo = EstadoArribaDer;
        if (FilaActual == 1 || ColumnaActual == AnchoGrid)
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end

        % Colisión por movimiento en diagonal
        if ismember(EstadoDerecha,EstadosObs) && ismember(EstadoArriba,EstadosObs)
            ColisionBorde = 1;
            EstadoFuturo = EstadoActual;

        % Colisión parcial por obstáculo a derecha
        elseif ismember(EstadoDerecha,EstadosObs) && ~ismember(EstadoArriba,EstadosObs)
            ColisionParcial = 1;

        % Colisión parcial por obstáculo arriba
        elseif ~ismember(EstadoDerecha,EstadosObs) && ismember(EstadoArriba,EstadosObs)
            ColisionParcial = 1;
        end
        
        % El agente se mueve en diagonal
        isDiagonal = 1;

    % Abajo-izquierda
    case 7
        EstadoFuturo = EstadoAbajoIzq;
        if (FilaActual == AltoGrid || ColumnaActual == 1)
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end

        % Colisión por movimiento en diagonal
        if ismember(EstadoAbajo,EstadosObs) && ismember(EstadoIzquierda,EstadosObs)
            ColisionBorde = 1;
            EstadoFuturo = EstadoActual;

        % Colisión parcial por obstáculo abajo
        elseif ismember(EstadoAbajo,EstadosObs) && ~ismember(EstadoIzquierda,EstadosObs)
            ColisionParcial = 1;

        % Colisión parcial por obstáculo a izquierda
        elseif ~ismember(EstadoAbajo,EstadosObs) && ismember(EstadoIzquierda,EstadosObs)
            ColisionParcial = 1;
        end
        
        % El agente se mueve en diagonal
        isDiagonal = 1;

    % Abajo-derecha
    case 8
        EstadoFuturo = EstadoAbajoDer;
        if (FilaActual == AltoGrid || ColumnaActual == AnchoGrid)
            ColisionBorde = 1;                  % Hubo colisión
            EstadoFuturo = EstadoActual;        % Se queda en el mismo lugar.
        end
        
        % Colisiones:
        % Colisión por movimiento en diagonal
        if ismember(EstadoAbajo,EstadosObs) && ismember(EstadoDerecha,EstadosObs)
            ColisionBorde = 1;
            EstadoFuturo = EstadoActual;

        % Colisión parcial por obstáculo abajo
        elseif ismember(EstadoAbajo,EstadosObs) && ~ismember(EstadoDerecha,EstadosObs)
            ColisionParcial = 1;

        % Colisión parcial por obstáculo a derecha
        elseif ~ismember(EstadoAbajo,EstadosObs) && ismember(EstadoDerecha,EstadosObs)
            ColisionParcial = 1;
        end
        
        % El agente se mueve en diagonal
        isDiagonal = 1;
end

% ===================================
% Recompensas
% ===================================

% R0: Recompensa inicial
Recompensa = 0;

% R1: Llega a la meta
if ismember(EstadoFuturo,EstadosMeta)
    Recompensa = Recompensa + 100000;

% R2: Agente no ha llegado a la meta
else
    Recompensa = Recompensa - 1;
end

% R3: Movimiento es diagonal
if isDiagonal
   Recompensa = Recompensa - 1; 
end

% R4: Agente choca con un borde
if ismember(EstadoFuturo,EstadosObs) || ColisionBorde
    Recompensa = Recompensa - 0;
    EstadoFuturo = EstadoActual;
end

% R5: El agente se "medio choca" o topa con borde
if ColisionParcial
    Recompensa = Recompensa - 1;
end
 

end