function [X,Y,Z] = DrawObstacles(Figura,Altura,ZOffset,varargin)
% DRAWOBSTACLES Función que permite decidir la forma de los obstáculos que
% se desplegarán sobre el escenario y en base a esto genera las coordenadas
% necesarias para graficar los mismos en 2D o 3D.
% -------------------------------------------------------------------------
% Inputs: 
%   - Figura: Tipo de figura a graficar. Existen tres opciones: "Cilindro",
%     "Poligono" y "Custom".
%   - Altura: Altura de la geometría a graficar. Aunque la geometría sea 2D
%     la función necesita de una altura para generar las coordenadas Z del
%     polígono.
%   - ZOffset: Altura de la cara inferior del polígono a crear. En otras
%     palabras, el nivel de Z sobre el que el polígono estará "sentado".
%
% Inputs Opcionales: 
%   Figura = "Cilindro" 
%   1. Radio: Radio del cilindro.
%
%   Figura = "Poligono"
%   1. LimsX: Límites de la mesa de trabajo en X.
%   2. LimsY: Límites de la mesa de trabajo en Y.
%   3. Meta: Punto a alcanzar por los robots
%   4. PuntoPartida: Punto del que salen los robots.
%
%   Figura = "Custom"
%   1. X: Vértices en X del polígono 2D
%   2. Y: Vértices en Y del polígono 2D
%
%   Figura = "Imagen"
%   1. Path: Path o nombre de la imagen con el mapa que se desea importar.
%      El mapa debe ser en blanco y negro, con los obstáculos en negro.
%      Se aceptan tanto imágenes .jpg como .png. Ejemplo: "Pentágono.jpg". 
%
% Outputs:
%   - X: Vector columna con las coordenadas X de todos los vértices que
%     conforman la geometría del obstáculo. La primera y última coordenada
%     coinciden para que la figura "cierre" al momento de graficarla con
%     fill() u otras funciones.
%   - Y: Vector columna con las coordenadas Y de los vértices que conforman
%     la geometría del obstáculo. La primera y última coordenada son
%     replicas.
%   - Z: Vector columna con las coordenadas Z de los vértices que conforman
%     la geometría del obstáculo. La primera y última coordenada son
%     replicas.
% -------------------------------------------------------------------------
% 
% Opciones "Figura"
%
%   - Cilindro: Cilindro centrado en el origen con un radio que es
%     especificado por el usuario.
%   - Poligono: El usuario puede dibujar un polígono que desee colocar en
%     el escenario como un obstáculo. En la ventana abierta, se muestra el
%     punto de partida y la meta a alcanzar para así evitar dibujar el
%     polígono sobre estas regiones.
%   - Custom: El usuario puede alimentarle directamente los vértices de un
%     polígono previamente creado y la función los adapta para que sean
%     compatibles con la forma requerida (Misma coordenada al inicio y al
%     final. Con offset y altura en Z).
%   - Imagen: El usuario puede alimentar al programa una imagen en blanco y
%     negro del mapa que desea, y este lo convierte automáticamente en un 
%     grupo de polígonos que pueden ser utilizados por el simulador para
%     recrear el ambiente en la mesa de trabajo.
% 
% -------------------------------------------------------------------------

switch Figura
    case "Cilindro"
        Radio = varargin{1};
        [X,Y,Z] = cylinder(Radio);
        Z = Z * Altura;
        Z = Z + ZOffset;
        
        X = X';
        Y = Y';
        Z = Z';
    
    case "Poligono"
        % Extracción de los parámetros requeridos del Varargin
        LimsX = varargin{1};
        LimsY = varargin{2};
        Meta = varargin{3};
        BordesRegionPartida = varargin{4};
        
        % Creación de figura
        figure('Name',"Creación de Obstáculos",'NumberTitle',"off"); clf; 
        grid minor; hold on; axis equal;
        axis([LimsX(1) LimsX(2) LimsY(1) LimsY(2)]);
        
        % Indicador de Meta
        scatter(Meta(1),Meta(2),'x','red','LineWidth',2);
        text(Meta(1),Meta(2),"Meta",'VerticalAlignment','cap','HorizontalAlignment','center','Fontsize',7);
        
        % Indicador de la región de partida
        VertsRegionPartida = [BordesRegionPartida(1,1) BordesRegionPartida(1,1) BordesRegionPartida(2,1) BordesRegionPartida(2,1) BordesRegionPartida(1,1) 
                              BordesRegionPartida(1,2) BordesRegionPartida(2,2) BordesRegionPartida(2,2) BordesRegionPartida(1,2) BordesRegionPartida(1,2)]';
        RegionPartida = polyshape(VertsRegionPartida);
        plot(RegionPartida,'Facealpha',0.2,'Facecolor','blue');
        text(BordesRegionPartida(1,1),BordesRegionPartida(2,2),"Region de Partida",'VerticalAlignment','bottom','HorizontalAlignment','left','Fontsize',7);
        
        Dibujo = drawpolygon();
        X = Dibujo.Position(:,1);
        Y = Dibujo.Position(:,2); 
        
        % Se agrega la primera pareja de coordenadas al final de todas las
        % demás coordenadas para que las funciones de patch() o fill()
        % cierren el polígono al dibujarlo.
        X = [X ; X(1)];
        Y = [Y ; Y(1)];
        
        % Cuando los polígonos se grafican en 3D, estos consisten de
        % básicamente una extrusión del polígono 2D en la dirección Z+.
        % Entonces la cara base y la cara superior van a tener las mismas
        % coordenadas X y Y, pero diferentes Z's. Por eso, se agrega una
        % columna adicional a X y Y replicando los datos ya existentes.
        X = repmat(X,1,2);
        Y = repmat(Y,1,2);
        
        % La altura preliminar del sólido extruido es de 1 (Z = 0 para la
        % cara inferior y Z = 1 para la cara superior). 
        %   - Al multiplicar por "Altura" la cara superior se extiende 
        %     hasta llegar a la altura deseada. 
        %   - Al sumar el offset, la altura de las dos caras se modifica, 
        %     desplazando al polígono sobre el eje Z.
        Z = [zeros(size(X,1),1) ones(size(X,1),1)];
        Z  = Z * Altura;
        Z = Z + ZOffset;
        close(gcf);
    
    case "Custom"
        
        X = varargin{1};
        Y = varargin{2};
        
        X = repmat(X,1,2);
        Y = repmat(Y,1,2);
        
        Z = [zeros(size(X,1),1) ones(size(X,1),1)];
        Z  = Z * Altura;
        Z = Z + ZOffset;
        
    case "Imagen"
        
        Path = varargin{1};
        
        % Para más información sobre esta rutina se puede escribir "help
        % ImportadorMapa" en consola o se puede acceder al importador más
        % manual presente en la ruta base del toolbox.
        Vertices = ImportarMapa(Path);
        
        X = repmat(Vertices(:,1),1,2);
        Y = repmat(Vertices(:,2),1,2);
        
        Z = [zeros(size(X,1),1) ones(size(X,1),1)];
        Z  = Z * Altura;
        Z = Z + ZOffset;
end
        
end

