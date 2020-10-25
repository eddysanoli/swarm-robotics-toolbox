function [MetaActual] = UpdateGoal(MetaActual, PosRobots, Trayectorias, isCiclica, varargin)
% UPDATEGOAL Función que mide la distancia del robot a su meta actual y si
% esta es lo suficientemente pequeña, entonces actualiza la meta actual al 
% siguiente punto en la trayectoria que está siguiendo el robot. 
% -------------------------------------------------------------------------
% Inputs:
%   - MetaActual: Meta o metas que actualmente están siguiendo los robots.
%     Cada columna representa una coordenada (X,Y). Si solo se provee una
%     pareja coordenada, se asume que todos los robots siguen un 
%   - PosRobots: Pareja de coords (X,Y), correspondientes a la posición
%     de cada uno de los robots. Cada fila representará la posición de un
%     robot diferente.
%   - Trayectoria: Puntos consecutivos a seguir por los diferentes robots.
%     Según el caso de seguimiento, este vector puede consistir de una
%     matriz tridimensional de [NoRobots,2,NoPuntosTrayectoria] (Meta
%     Individual) o de una matriz bidimensional de [NoRobots,2] (Meta
%     única)
%   - isCiclica: Al llegar al último punto en su trayectoria, el robot debe
%     volver a regresar a su primer punto?
%
% Outputs:
%   - MetaActual: Meta actual de los robots actualizada según su distancia
%     a la previa "meta actual".
%
% -------------------------------------------------------------------------        
%
% Existen dos casos de seguimiento de trayectorias:
%
% - Meta única: Una meta común para todos los robot. En este caso el vector
%   de trayectorias es bidimensional, con cada fila representando un nuevo 
%   punto a buscar.
% - Multi-meta: Una meta para cada robot. En este caso el array de 
%   trayectorias es tridimensional, con cada fila representando la meta de 
%   un robot diferente y cada "capa" o "profundidad" representando una 
%   nueva meta para los pucks. 
%
% -------------------------------------------------------------------------
%
% Parámetros:
%   - 'ThresholdDist_MetaUnica': Threshold de distancia utilizado para
%     determinar la cercanía de los robots a la meta en el caso de "meta
%     única". Default = 0.6;
%   - 'ThresholdDist_MultiMeta': Threshold de distancia utilizado para
%     determinar la cercanía de cada uno de los robots a la meta en el caso 
%     de "multi-meta". Default = 0.3;
%
% ------------------------------------------------------------------

% Se crea el objeto encargado de "parsear" los inputs
IP = inputParser;  

% Inputs Obligatorios / Requeridos: Necesarios para el funcionamiento 
% del programa. La función da error si el usuario no los pasa.                                                     
IP.addRequired('MetaActual', @isnumeric);
IP.addRequired('PosRobots', @isnumeric);
IP.addRequired('Trayectorias', @isnumeric);
IP.addRequired('isCiclica', @isnumeric);

% Parámetros: Similar a cuando se utiliza 'FontSize' en plots. El
% usuario debe escribir el nombre del parámetro a modificar seguido
% de su valor. Si no se provee un valor Matlab asume uno "default".
IP.addParameter('ThresholdDist_MetaUnica', 0.6, @isnumeric);
IP.addParameter('ThresholdDist_MultiMeta', 0.4, @isnumeric);
IP.parse(MetaActual,PosRobots,Trayectorias,isCiclica,varargin{:});

% Se guardan los inputs "parseados" en variables útiles capaces
% de ser utilizadas por el programa.
ThresholdDist_MetaUnica = IP.Results.ThresholdDist_MetaUnica;
ThresholdDist_MultiMeta = IP.Results.ThresholdDist_MultiMeta;
NoPucks = size(PosRobots,1);

% Caso: Meta Única
if size(MetaActual,1) == 1

    % Se obtiene la distancia de cada Puck a la meta actual
    [~,RobotDist_Meta] = dsearchn(MetaActual,PosRobots);

    % Si la media de las distancias es menor al threshold, se
    % cambia a una nueva meta.
    if mean(RobotDist_Meta) < ThresholdDist_MetaUnica
        
        % En caso el vector de trayectorias sea tridimensional (ndims == 3)
        % este se convierte en una matriz bidimensional
        if ndims(Trayectorias) == 3
            Trayectorias = squeeze(Trayectorias)';
        end
        
        % Se extrae el número de meta actual.
        [~,NoMetaActual] = ismember(MetaActual,Trayectorias,'rows');

        % Si se ha llegado a la última meta en la trayectoria
        if size(Trayectorias,1) == NoMetaActual   

            % Si la trayectoria es cíclica
            if isCiclica
                NoMeta = 1;                                 % Se regresa al primer punto de la trayectoria

            % Si la trayectoria no es cíclica
            else
                NoMeta = NoMetaActual;                      % Ya no se cambia la meta
            end

        % Si no se ha llegado a la última meta de la trayectoria
        else
            NoMeta = NoMetaActual;
            NoMeta = NoMeta + 1;                            % Se pasa a la siguiente meta.
        end

        MetaActual = Trayectorias(NoMeta,:);

    end
    
% Caso: Meta distinta por Robot
elseif size(MetaActual,1) == NoPucks

    % Se obtiene la distancia de cada Puck a su meta actual
    RobotDist_Meta = hypot(MetaActual(:,1)-PosRobots(:,1), ...
                           MetaActual(:,2)-PosRobots(:,2));

    % Números de fila correspondientes a los pucks que han llegado
    % a su meta respectiva.
    RobotCercanosMeta = find(RobotDist_Meta < ThresholdDist_MultiMeta);

    % Se analiza cada puck que ha llegado a la meta (En caso
    % existan / PucksCercanosMeta no está vacío).
    if ~isempty(RobotCercanosMeta)

        for RobotSeleccionado = 1:numel(RobotCercanosMeta)

            % Se extrae el índice del robot a analizar
            k = RobotCercanosMeta(RobotSeleccionado);

            % Se extrae un array 2D con la trayectoria a seguir por 
            % el robot "k".
            TrayectoriaRobot_Individual = squeeze(Trayectorias(k,:,:))';

            % Se extrae el número de meta actual.
            [~,NoMetaActual] = ismember(MetaActual(k,:),TrayectoriaRobot_Individual,'rows');

            % Si se ha llegado a la última meta en la trayectoria
            if size(TrayectoriaRobot_Individual,1) == NoMetaActual   

                % Si la trayectoria es cíclica
                % Se regresa al primer punto de la trayectoria
                if isCiclica
                    NoMeta = 1;                                 

                % Si la trayectoria no es cíclica
                % Ya no se cambia la meta
                else
                    NoMeta = NoMetaActual;                      
                end

            % Si no se ha llegado a la última meta de la trayectoria
            % Se pasa a la siguiente meta.
            else
                NoMeta = NoMetaActual;
                NoMeta = NoMeta + 1;                            
            end

            % Se actualiza la meta actual para el Puck "k"
            MetaActual(k,:) = Trayectorias(k,:,NoMeta);

        end

    end
            
end

