function [varargout] = plotGridPolicy(Policy, EstadosObs, EstadosMeta, LineasVertGrid, LineasHoriGrid, varargin)
% PLOTGRIDPOLICY Función que permite visualizar la policy perteneciente al
% problema de "Gridworld". Este no solo grafica la cuadrícula asociada al
% problema (Incluyendo los ID's numéricos que identifican a cada estado), 
% sino también la flechas que simbolizan la acción óptima a tomar en cada 
% estado. El largo de las flechas y los ID's se cambia automáticamente, los
% ID's desaparecen si su tamaño se torna ilegible dado el número de estados
% -------------------------------------------------------------------------
% Inputs:
%   - Policy: Vector que contiene las probabilidades de tomar cada acción
%     disponible en cada uno de los estados existentes. Dims: (NoEstados,
%     NoAcciones)
%   - EstadosObs: ID de los estados de la cuadrícula o "grid" que contienen
%     obstáculos. Vector columna o fila.
%   - EstadosMeta: ID de los estados de la cuadrícula o "grid" que
%     contienen una o más metas. Vector columna o fila.
%   - LineasVertGrid: Coordenadas X correspondientes a las líneas
%     verticales que forman las divisiones verticales de la cuadrícula. Si
%     existen 30 celdas de ancho, existirán 31 divisiones verticales.
%   - LineasHoriGrid: Coordenadas Y correspondientes a las líneas
%     horizontales que forman las divisiones verticales de la cuadrícula.
%     Si existen 30 celdas de alto, existirán 31 divisiones horizontales.
%
% Parámetros Opcionales:
%   - 'DisableIDs': 1 si se desea deshabilitar los números que indican el
%     "nombre" de cada estado. 0 si se desea que el ajuste automático de
%     los IDs permanezca inalterado.
%
% Outputs Opcionales:
%   - GridPlot: Handle para la gráfica de la cuadrícula (Líneas verticales
%     y horizontales) del grid.
%   - PolicyPlot: Handle para la gráfica de las flechas que representan la
%     policy a seguir por el agente.
%
% -------------------------------------------------------------------------    
% 
% Ejemplo: Los números consisten de los IDs y las flechas de la policy
%
%    ---------------------------------------
%   | 1     | 5     | 9     | 13    | 17    |
%   |   ↘   |   ↓   |   ↙   |   ↙  |   ↙   |
%    ---------------------------------------
%   | 2     | 6     | 10    | 14    | 18    |
%   |   →  | META  |   ←   |   ←  |   ←   |
%    ---------------------------------------
%   | 3     | 7     | 11    | 15    | 19    |
%   |   ↗   |   ↑   |   ↖   |   ↖   |   ↖  |
%    ---------------------------------------
%   | 4     | 8     | 12    | 16    | 20    |
%   |   ↗   |   ↑   |   ↖   |   ↖  |   ↖   |
%    ---------------------------------------
%
% -------------------------------------------------------------------------   

% Se crea el objeto encargado de "parsear" los inputs
IP = inputParser;  

% Inputs Obligatorios / Requeridos: Necesarios para el funcionamiento 
% del programa. La función da error si el usuario no los pasa.                                                     
IP.addRequired('Policy', @isnumeric);
IP.addRequired('EstadosObs', @isnumeric);
IP.addRequired('EstadosMeta', @isnumeric);
IP.addRequired('LineasVertGrid', @isnumeric);
IP.addRequired('LineasHoriGrid', @isnumeric);

% Parámetros: Similar a cuando se utiliza 'FontSize' en plots. El
% usuario debe escribir el nombre del parámetro a modificar seguido
% de su valor. Si no se provee un valor Matlab asume uno "default".
IP.addParameter('DisableIDs', 0, @isnumeric);
IP.parse(Policy, EstadosObs, EstadosMeta, LineasVertGrid, LineasHoriGrid,varargin{:});

% Se guardan los inputs "parseados" en variables útiles capaces
% de ser utilizadas por el programa.
DisableIDs = IP.Results.DisableIDs;

% -------------------------------------------------------------------------    

% Definición de dimensiones de cuadrícula
NoColumnasGrid = numel(LineasVertGrid) - 1;
NoFilasGrid = numel(LineasHoriGrid) - 1;

% Dimensiones de cada celda en la grid
AltoCelda = LineasHoriGrid(2) - LineasHoriGrid(1);
AnchoCelda = LineasVertGrid(2) - LineasVertGrid(1);

% Vector con todos los estados en la forma de una lista.
Estados = 1:(NoColumnasGrid * NoFilasGrid);

% Matriz de estados. Matriz con los "nombres" de cada estado en su
% posición dentro de la cuadrícula. Para una grid de 3x3 se tiene la
% siguiente forma:
%
%   | 1 | 4 | 7 |
%   | 2 | 5 | 8 |
%   | 3 | 6 | 9 |
%
MatrizEstados = reshape(Estados,NoFilasGrid,NoColumnasGrid);

% Componentes direccionales para las flechas que se van a graficar
% utilizando "quiver()" para representar las ocho acciones que puede tomar
% el agente.
Direcciones = [ 0  1    % Arriba
                0 -1    % Abajo
               -1  0    % Izquierda
                1  0    % Derecha
               -1  1    % Arriba-izquierda
                1  1    % Arriba-derecha
               -1 -1    % Abajo-izquierda
                1 -1];  % Abajo-derecha

% Se escala el tamaño de las flechas
Direcciones = Direcciones .* ([AnchoCelda/2 AltoCelda/2] * 0.7);

% De la policy, se extraen todas las acciones que tengan una probabilidad
% distinta de 0. Específicamente se extrae el estado en que ocurre la acción
% y el índice de la acción como tal. "find(Policy)" aquí hace lo mismo que
% "find(Policy ~= 0)".
[EstadosOptimos, AccionesOptimas] = find(Policy);

% Vector que contiene las policies o las direcciones en las que se puede
% mover el agente.
CompsFlechas = zeros(numel(EstadosOptimos),2);

% Posición en la que inician todas las colas de las flechas.
PosColasFlechas = zeros(numel(EstadosOptimos),2);

for i = 1:numel(EstadosOptimos)

    % Componentes (X,Y) de la flecha actual
    CompsFlechas(i,:) = Direcciones(AccionesOptimas(i),:);

    % Posiciones de las colas de las flechas (Fila y columna dentro de la
    % grid que corresponde al estado dado).
    [FilaEstado, ColEstado] = find(MatrizEstados == EstadosOptimos(i));
    PosColasFlechas(i,:) = [LineasVertGrid(ColEstado) LineasHoriGrid(FilaEstado)];

    % Si el estado óptimo actual "i" es un obstáculo o meta, no se le
    % grafica una flecha de policy.
    if ismember(EstadosOptimos(i),EstadosMeta) || ismember(EstadosOptimos(i),EstadosObs)
        CompsFlechas(i,:) = 0;
    end
end

% Las posiciones de las colas de las flechas están dadas en términos 
% de su número de fila y columna dentro de la matriz de estados. Esto
% implica que, para un grid de 3x3, las coordenadas del estado 1 serán
% (1,1) ya que ocupa la fila 1, columna 1 en la matriz de estados. 
% 
%       C1  C2  C3 
%   F1   1   4   7
%   F2   2   5   8
%   F3   3   6   9
% 
% Lo malo es que los bordes de la grid se grafican en el plano cartesiano o
% con su esquina inferior izquierda en la coordenada (0,0). Entonces, si se
% grafica la cola de la flecha en (1,1), esta no aparecerá centrada en el
% estado 1, sino en el estado 3. El estado 1, está en realidad en la coord.
% (1,3) del plano cartesiano.
% 
%   Y3   1   4   7
%   Y2   2   5   8
%   Y1   ↗   6   9
%       X1  X2  X3
% 
% Para corregir esto, se hace un flip vertical colocando todas las
% coordenadas en Y negativas, y luego restándoles el alto de una celda

PosColasFlechas(:,2) = - PosColasFlechas(:,2) - AltoCelda;

% Ahora solo tenemos un último problema. Las celdas de la cuadrícula tienen
% un largo y alto unitario. Esto implica que una flecha graficada en la
% coordenada (1,1) va a graficarse en la esquina superior derecha del
% estado 3 del ejemplo. Para centrar la flecha, le realizamos un desfase en
% X y Y, de 0.5 positivo.

PosColasFlechas = PosColasFlechas + [AnchoCelda/2 AltoCelda/2];

% Setup de gráfica
hold on;

% Graficación de Cuadrícula
Cuadricula = ones(NoFilasGrid, NoColumnasGrid);             % Matriz de 1's (blanca) 
Cuadricula(EstadosMeta) = 0.8;                              % Gris claro para metas
Cuadricula(EstadosObs) = 0;                                 % Gris oscuro para los obstáculos 
Cuadricula = flipud(Cuadricula);                            % Se hace un mirror en Y para que los colores aparezcan donde son
Cuadricula = [Cuadricula zeros(NoFilasGrid,1)];             % Se agrega padding a la derecha o la gráfica no muestra cuadricula a la derecha
Cuadricula = [Cuadricula; zeros(1,NoColumnasGrid+1)];      	% Se agrega padding abajo o la gráfica no muestra cuadrícula en la primera fila

% Gráfica de la cuadrícula y las celdas coloreadas
[LineasVert, LineasHori] = meshgrid(LineasVertGrid,LineasHoriGrid);
GridPlot = surf(LineasVert, LineasHori,Cuadricula-0.1,'FaceAlpha',0.2);
colormap gray;

% Se grafican las flechas de la policy
PolicyPlot = quiver(PosColasFlechas(:,1),PosColasFlechas(:,2), CompsFlechas(:,1),CompsFlechas(:,2), 0, ...
                    'LineWidth',1.5,'MaxHeadSize',12);

OldUnits = get(gcf, 'Units');                                       % Unidades de los ejes actuales
set(gcf, 'Units', 'points');                                        % Se cambian las unidades de los ejes a puntos
PosFig_Puntos = get(gcf, 'Position');                               % Se obtiene el [left bottom width height] de la caja que encierra a los ejes
set(gcf, 'Units', OldUnits);                   

% Número de puntos en cada celda de la grid graficada
PuntosPorCelda_Largo = PosFig_Puntos(3) / NoColumnasGrid;

% Cantidad máxima de dígitos que va a existir en cada ID de estado. Por
% ejemplo si hay 100 estados, el número máximo de dígitos será 3 porque 100
% tiene 3 dígitos.
NoDigitosMax = numel(num2str(max(Estados)));

% Ancho de texto en label de ID
% - Se cubre el 70% del ancho de la celda en puntos
% - Se divide dicha distancia dentro del número de dígitos, para que el
%   estado con el mayor número de dígitos ocupe el 70% de la celda.
AnchoMaxID_Puntos = (PuntosPorCelda_Largo * 0.7) / NoDigitosMax;

% Solo se grafican los IDs de cada estado en caso estos tengan un tamaño
% mayor a 6 pts. Si su tamaño es menor, el texto es virtualmente ilegible,
% por lo que no vale la pena graficarlo.
if (AnchoMaxID_Puntos > 6) && ~DisableIDs
    
    % Label con el "nombre" de cada estado o con el ID numérico que le
    % corresponde a cada estado. "Num" representa el ID de dicho estado.
    Num = 1;
    for i = 1:NoColumnasGrid
        for j = NoFilasGrid:-1:1
            text(LineasVertGrid(i)+(AnchoCelda*0.08), LineasHoriGrid(j)+(AltoCelda*0.7), num2str(Num),'FontSize',AnchoMaxID_Puntos);
            Num = Num + 1;
        end
    end
    
end
    
varargout{1} = GridPlot;
varargout{2} = PolicyPlot;

end

