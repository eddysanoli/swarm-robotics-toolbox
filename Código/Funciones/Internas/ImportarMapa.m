function [Vertices] = ImportarMapa(PathImagen)
% IMPORTARMAPA Función que permite importar un mapa en blanco y negro
% presente en una imagen (Con los obstáculos en negro), al extraer los
% vértices que conforman los obstáculos en cuestión. Estos pueden ser luego
% graficados utilizando "polyshape()" y luego "plot()".
% -------------------------------------------------------------------------
% Inputs: 
%   - PathImagen: Ruta de la imagen que se desea importar. Si la imagen se
%     encuentra en el directorio base (Lo recomendado) solo hace falta
%     colocar el nombre y formato de la imagen. Se permite el uso de
%     imágenes .png y .jpg. Ejemplo: "Pentágono.jpg".
%
% Outputs:
%   - Vertices: Array de (NoVertices x 2) conteniendo las coordenadas de 
%     los vértices de él o los obstáculos presentes en el mapa. En caso se
%     tengan múltiples obstáculos, sus coordenadas estarán separadas por
%     "NaNs".
%
% -------------------------------------------------------------------------
%
% NOTA: Esta función utiliza una gran cantidad de parámetros, e incluso
% cuenta con una forma alternativa de calcular el "travelling salesman
% problem". Si se desea mayor control sobre el proceso, se provee una
% versión alternativa y mucho más personalizable en el script
% "Importar_Mapa.mlx". Ahí se explican algunas cosas adicionales y se
% presentan todos los parámetros que el algoritmo utiliza, aunque la
% documentación es exactamente la misma a la presente en esta función.
%
% -------------------------------------------------------------------------

% ===============================================
% EVITAR LECTURAS REDUNDANTES DE LA MISMA IMAGEN
% ===============================================

% Cuadradito unitario retornado cuando ocurre un error en el procesamiento
% de vértices o el usuario no desea procesar los vértices.
CuadraditoError = [0 0 1 1; 0 1 1 0]';

% Path a la carpeta con las imágenes de los mapas
PathImMapa = ".\Mapas\Imágenes\";

% Se busca la imagen en el directorio actual
if isfile(PathImagen)
    ImagenMapa = imread(PathImagen);

% Si no está en el path actual, se busca en los mapas guardados
elseif isfile(PathImMapa + PathImagen)
    ImagenMapa = imread(PathImMapa + PathImagen);

% Si no se encuentra en ninguna ruta, se retorna un error.
else
    error("Error: No existe la imagen especificada en el directorio actual");
end

% Se convierte la imagen a blanco y negro si la imagen tiene una tercera
% dimensión (Está a color).
if ndims(ImagenMapa) == 3
    ImagenMapa = rgb2gray(ImagenMapa);
end

% Se extrae el nombre de la imagen (Sin ruta o extensión)
[~,NombreImagen,~] = fileparts(PathImagen);

% Se extraen todas las imágenes "png" y "jpg" dentro del directorio de
% mapas guardados
DatosArchivos = [dir(fullfile(PathImMapa,'*.png')) ; dir(fullfile(PathImMapa,'*.jpg'))];
SSIMVal = zeros(numel(DatosArchivos),1);

% Se revisa cada elemento dentro de la carpeta de "imágenes" de mapas
for i = 1:numel(DatosArchivos)

    % Se abre cada archivo y 
    F = fullfile(PathImMapa,DatosArchivos(i).name);
    I = imread(F);

    % Si el tamaño de dos imágenes coincide, se saca el índice de 
    % similitud directamente
    if size(ImagenMapa) == size(I)
        SSIMVal(i) = ssim(I,ImagenMapa);

    % Si el tamaño de las dos imágenes no coincide, primero se 
    % redimensiona la imagen guardada para que coincida con la que se 
    % abrió.
    else
        I = imresize(I,[size(ImagenMapa,1), size(ImagenMapa,2)]);
        SSIMVal(i) = ssim(I,ImagenMapa);
    end
end

[Similitud,MejorCoincidencia] = max(SSIMVal);

% Si la mejor coincidencia con la imagen a analizar está por encima del 90%. 
if Similitud > 0.9
    
    % Directorio conteniendo datos de las imágenes
    PathVertices = ".\Mapas\Vertices\";
    DatosVertices = dir(fullfile(PathVertices,'*.mat'));
    
    % Se asume que no existen datos para la imagen
    DatosEncontrados = 0;
    
    % Se buscan coincidencias entre los nombres de las imágenes en
    % "Imágenes" y los vértices en "Vértices".
    for i = 1:numel(DatosVertices)
        
        [~,NombreMat,~] = fileparts(DatosVertices(i).name);
        
        if strcmp(NombreImagen, NombreMat)
            DatosEncontrados = 1;
            break;
        end
        
    end
    
    % Si se encontraron datos asociados a la imagen actual
    if DatosEncontrados
        Respuesta = questdlg('Mapa actual similar a uno previamente procesado. ¿Desea utilizar los datos del mapa previo?',...
                             'Importador de Mapas','Si','No','No');
        
        switch Respuesta
            case "Si"
               	PathCoincidencia = DatosArchivos(MejorCoincidencia).name;
                [~,NombreCoincidencia,~] = fileparts(PathCoincidencia);
                load(".\Mapas\Vertices\" + NombreCoincidencia + ".mat");
                Vertices = VerticesClean;
                disp("Datos de mapa cargados");
                ProcesarImagen = 0;
                
            case "No"
                disp("Importador Mapas: Procesando Imagen...");
                ProcesarImagen = 1;
                
            otherwise
                error("Error: Respuesta no válida");
                
        end
    
    % Si no se encontraron datos asociados a la imagen actual
    else
        Respuesta = questdlg('Mapa a procesar carece de vértices asociados al mismo. ¿Desea generar dichos vértices?',...
                             'Importador de Mapas','Si','No','No');
        
         switch Respuesta
            case "Si"
                disp("Importador Mapas: Procesando Imagen...");
                ProcesarImagen = 1;
                
            case "No"
                disp("Error: No hay datos para trabajar. Usando cuadrito");
                Vertices = CuadraditoError;
                ProcesarImagen = 0;
                
            otherwise
                error("Error: Respuesta no válida");
                
         end
        
    end

else
    ProcesarImagen = 1;
end

% ===============================================
% PROCESADO DE IMAGEN 
% ===============================================

if ProcesarImagen
    
    % ===============================================
    % LECTURA IMAGEN Y EXTRACCIÓN DE BORDES
    % ===============================================
    
    % Thresholding para limpiar cualquier mancha en escala de grises
    Mapa = ImagenMapa < 250;

    % Celda conteniendo en cada uno de sus elementos un conjunto de coordenadas
    % que definen los diferentes obstáculos o elementos en el mapa.
    [Bordes,~,NoBordes,~] = bwboundaries(Mapa);

    % Número de puntos que debe tener un borde para ser considerado válido
    ThresholdPuntos = 100;

    % Inicialización de variables para el for-loop
    Puntos = [];
    i = 1;

    % Visualización de los bordes. No se utiliza un for-loop porque el número
    % de loops depende del NoBordes y el número de bordes cambia de forma
    % dinámica conforme se limpia la detección.
    while i <= numel(Bordes)

        % Se grafican los bordes con más de "ThresholdPuntos"
        if size(Bordes{i},1) > ThresholdPuntos
            Puntos = [Puntos; Bordes{i}];
            i = i + 1;

        % Se eliminan los bordes con menos de "ThresholdPuntos" para eliminar
        % bordes "ruidosos" o insignificantes.
        else
            Bordes(i) = [];
            NoBordes = NoBordes - 1;
        end

    end

    % Existe la posibilidad de que algunos mapas consistan de "paredes con
    % diferentes formas". En estos casos, los bordes exteriores del mapa no se
    % detectarán por estar pegados a los límites de la imagen. Para prevenir
    % que no se detecten, se le agrega un margen de blanco, alrededor de la
    % imagen.
    PadSize = 3;
    PaddedImagenMapa = padarray(ImagenMapa,[PadSize PadSize],255,'both');

    % Detección de las esquinas de los polígonos. 
    % Matlab recomienda utilizar métodos de la Computer Vision Toolbox, pero
    % al probarlas no resultaron tan útiles.
    %   - detectHarrisFeatures() no detecta esquinas en la parte de la imagen
    %     que esta pegada a arriba.
    %   - detectMinEigenFeatures() requiere de un parámetro adicional, el
    %     número de detecciones "fuertes" a filtrar, lo cual hace menos
    %     automático el proceso.
    %
    % A las esquinas obtenidas se les resta el tamaño del padding para
    % re-alinear los puntos con las coordenadas de los puntos extraidos 
    % previamente.
    Esquinas = corner(PaddedImagenMapa) - [PadSize PadSize];

    % Se mide la similitud entre los puntos obtenidos en "bwboundaries()" y en
    % "corner()" obteniendo la distancia euclideana de cada esquina a los "Puntos"
    % y luego determinando si las distancias son menores al threshold de error.
    ThresholdError = 2;
    [~,DistsError] = dsearchn([Puntos(:,2) Puntos(:,1)],Esquinas);

    % Si el número de esquinas con un error mayor al threshold de error es
    % mayor al número de errores máximo soportado, se ignoran las esquinas y se
    % supone que las esquinas son iguales a los puntos retornados por "bwboundaries()".
    NoErrores = 4;
    if sum(DistsError > ThresholdError) > NoErrores
        Esquinas = [Puntos(:,2) Puntos(:,1)];
    end
    
    % ===============================================
    % IDENTIFICACIÓN DE SECUENCIA DE PUNTOS
    % ===============================================
    
    % Basado en:
    % https://www.mathworks.com/help/optim/examples/travelling-salesman-problem.html

    NoPuntos = size(Puntos,1);
    IndxCombPosibles = nchoosek(1:NoPuntos, 2);
    Grafo = graph(IndxCombPosibles(:,1),IndxCombPosibles(:,2));

    % Coordenadas de puntos
    X = Puntos(:,2);
    Y = Puntos(:,1);

    % Básicamente nos ahorra el hacer sqrt(X.^2 + Y.^2)
    DistsEntrePuntos = hypot(X(IndxCombPosibles(:,1)) - X(IndxCombPosibles(:,2)), Y(IndxCombPosibles(:,1)) - Y(IndxCombPosibles(:,2)));
    LargoDist = length(DistsEntrePuntos);

    % Creación de variables y problema
    tsp = optimproblem;
    Conexiones = optimvar('trips',LargoDist,1,'Type','integer','LowerBound',0,'UpperBound',1);

    % Incluir la función objetivo en el problema
    tsp.Objective = DistsEntrePuntos'*Conexiones;

    % Creación de "Progress Bar" para ver como va el procesado de puntos
    ProgressBar = waitbar(0,'Procesando Puntos...');

    % Restricciones
    Constr2Conex = optimconstr(NoPuntos,1);
    for i = 1:NoPuntos

        % Identifica las conecciones asociadas con este punto
        whichIndx = outedges(Grafo,i);
        Constr2Conex(i) = sum(Conexiones(whichIndx)) == 2;

        % Actualización de barra de progreso
        waitbar(i / NoPuntos);
    end

    close(ProgressBar);
    tsp.Constraints.Constr2Conex = Constr2Conex;

    % Solucionar problema inicial
    Options = optimoptions('intlinprog','Display','off');
    tspsol = solve(tsp,'options',Options);

    % Extracción de solución
    X_tsp = logical(round(tspsol.trips));
    
    % ===============================================
    % REORDENAMIENTO DE COORDENADAS
    % ===============================================
    
    % Se extraen las parejas "conectadas" resueltas por el optimizador
    Parejas = [IndxCombPosibles(X_tsp,1) IndxCombPosibles(X_tsp,2)];
    NoPuntos = size(Parejas,1);

    % Basado en este post: 
    % https://www.mathworks.com/matlabcentral/answers/112226-sorting-a-list-of-edges

    % Array con los índices ordenados de la siguiente manera:
    % [1 4; 4 7; 7 10; 10 3; 3 6; 6 8]. 
    % En otras palabras, el array expresa una "cadena de conexión" (Punto 1 conectado
    % con punto 4, punto 4 conectado con 7, punto 7 conectado con 10, etc.)
    VerticeSort = zeros(NoPuntos,2);

    % Punto del que se parte el ordenamiento
    VerticeSort(1,:) = Parejas(1,:);

    % Vector binario que indica cuales son los puntos ya visitados. La posición
    VerticeVisit = zeros(NoPuntos,1);
    VerticeVisit(1) = 1;

    % Inicialización de número objetos
    NoObjeto = 1;
    OrdenObjetos = cell(NoBordes,1);
    i = 2;

    while i <= (NoPuntos)

         % Indice del punto actual del que se buscará su pareja (Valor en la
         % segunda columna de la fila previa del array de vértices ordenados).
         inod = VerticeSort(i-1,2);

         % Se obtienen todos los puntos que aún no se han colocado en la lista
         % "VerticeSort" y por lo tanto, consisten de los puntos que aún deben
         % interconectarse con otros puntos.
         iedg = find(VerticeVisit == 0);

         % Encontrar la fila (idx) y columna (jdx) donde aparece de nuevo el
         % punto actual a conectar (inod) dentro de la lista de parejas sin
         % interconectar (Parejas(iedg,:)).
         [idx,jdx] = find(Parejas(iedg,:) == inod);

         % El punto a interconectar se agrega en la columna 1 de la fila "i"
         % del array de vertices ordenados. Debemos encontrar el valor al que
         % está conectado o el valor en la segunda columna.
         VerticeSort(i,1) = inod;

         % Si no hay puntos sin interconectar que conecten con el punto actual
         % se asume que se llegó al final de los puntos que pertenecen al
         % objeto actual.
         if isempty(idx) || isempty(jdx)
             OrdenVerticesObjeto = VerticeSort(1:i-1,:);
             [~,IndParejasNorm] = intersect(Parejas,OrdenVerticesObjeto,"rows");
             [~,IndParejasFlip] = intersect(Parejas,fliplr(OrdenVerticesObjeto),"rows");

             IndAEliminar = [IndParejasNorm ; IndParejasFlip];

             Parejas(IndAEliminar,:) = [];      % Se eliminan los puntos presentes en el objeto completado
             NoPuntos = size(Parejas,1);        % Se actualiza al número de puntos total
             VerticeSort = zeros(NoPuntos,2);   % Se reinicia el vector de puntos ordenados
             VerticeSort(1,:) = Parejas(1,:);   
             VerticeVisit = zeros(NoPuntos,1);  % Se reinicia el vector de puntos visitados
             VerticeVisit(1) = 1;
             i = 2;                             % Se reinicia la cuenta de i

             OrdenObjetos{NoObjeto} = OrdenVerticesObjeto;
             NoObjeto = NoObjeto + 1;
             continue;                          % Se brinca de una vez a la siguiente iteración del while-loop
         end

         % Si la columna donde aparece el punto actual a conectar es la primera
         % columna del array "Parejas", el punto conectado a este consistirá
         % del número en la segunda columna de las "Parejas" no conectadas.
         if jdx == 1
             VerticeSort(i,2) = Parejas(iedg(idx),2); 

         % Si la columna donde aparece el punto actual es la segunda columna de
         % "Parejas" entonces se agrega el valor en la columna 1.
         else
             VerticeSort(i,2) = Parejas(iedg(idx),1);
         end

         % Actualizar la lista de puntos interconectados
         VerticeVisit(iedg(idx)) = 1;
         i = i + 1;

    end

    % Por el funcionamiento del loop anterior, existe la posibilidad que el
    % último objeto no se guarde en "OrdenObjetos" entonces a continuación se
    % guarda manualmente este elemento.
    if ~isempty(VerticeSort(1:i-1,:))
        OrdenObjetos{NoObjeto} = VerticeSort(1:i-1,:);
    end

    % Se reordenan los puntos de cada elemento según el orden deducido
    % previamente
    Vertices = cell(NoBordes,1);
    for i = 1:numel(OrdenObjetos)
        Orden = OrdenObjetos{i}(:,1);
        Vertices{i} = [Puntos(Orden,2) Puntos(Orden,1)];
    end
    
    % ===============================================
    % LIMPIEZA DE VERTICES REDUNDANTES
    % ===============================================
    
    VerticesClean = [];

    % Distancia en pixeles a la que debería de estar una esquina para ser
    % considerada "cercana" a un punto.
    ThresholdDist = 3;                          

    for i = 1:numel(Vertices)
        % Se obtiene
        %   - PuntosMasCercanos: Indices de "Vertices" que están más cercano a las
        %     esquinas actuales.
        %   - Distancias: Las distancias a dichos puntos más cercanos.
        [PuntosMasCercanos,Distancias] = dsearchn(Vertices{i},Esquinas);

        % Indice de los puntos más cercanos del objeto "i" que coinciden con las 
        % actuales esquinas.
        EsquinasCercanas = PuntosMasCercanos(Distancias < ThresholdDist,:);
        EsquinasUtiles = Esquinas(Distancias < ThresholdDist,:);

        % Se ordenan las esquinas encontradas en orden ascendente para que al
        % conectar los puntos usando un polígono, no existan cruces de líneas.
        [~,IndEsquinasAscen] = sort(EsquinasCercanas,'ascend');

        % Extracción de los vértices del objeto actual en orden correcto para
        % que puedan convertirse debidamente en un polígono. Se separa cada
        % objeto usando NaNs y el primer punto del polígono se repite al 
        % final.
        VerticesObjeto = EsquinasUtiles(IndEsquinasAscen,:);
        if ~isempty(VerticesObjeto)
            VerticesClean = [VerticesClean ;
                             VerticesObjeto;
                             VerticesObjeto(1,:);
                             NaN NaN];
        end
        
        
    end
    
    % ===============================================
    % GUARDADO DE DATOS
    % ===============================================
    
    % Se guardan la imagen procesada y los vértices extraídos
    imwrite(ImagenMapa, ".\Mapas\Imágenes\" + PathImagen);
    save(".\Mapas\Vertices\" + NombreImagen + ".mat","VerticesClean");
    Vertices = VerticesClean;
    disp("Importador Mapas: Procesado Finalizado!");
    
end
    
end

