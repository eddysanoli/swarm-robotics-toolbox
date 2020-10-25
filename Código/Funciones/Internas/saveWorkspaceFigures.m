function [] = saveWorkspaceFigures(Path,Extension)
% SAVEWORKSPACEFIGURES Todas las figuras guardadas por el usuario en la
% workspace base de Matlab son guardadas en el Path especificado como 
% imágenes en el formato especificado por el usuario. 
% -------------------------------------------------------------------------
% Input:
%   - Path: Carpeta en la que se guardarán todas las figuras desplegadas y
%     almacenadas actualmente en la workspace.
%   - Extension: Formato de las imágenes en el que se guardarán las figuras
%     generadas y guardadas. Ejemplos: "png" o "jpg".
%
% -------------------------------------------------------------------------
%
% Nota: Para que funcione correctamente la función, las figuras que desean 
% guardarse como imágenes deben ser guardadas como variables en la 
% workspace. Por ejemplo:
%
%   scatter(XData,YData,'LineWidth',1.5);
%   No se guardará como imagen.
%
%   Puntos = (XData,YData,'LineWidth',1.5);
%   Si se guardará como imagen.
%
% -------------------------------------------------------------------------

% Se extrae la información de las variables presentes en el workspace
% Esto incluye su nombre, dimensiones, número de bytes que ocupa y el tipo
% o clase de dato que contiene. Para esto se ejecuta la función "who()"
% dentro de la workspace "base".
DataVariablesWorkspace = evalin('base','whos');

% Se extrae el número de fila correspondiente a todas aquellas variables
% que pertencen a la clase "figura".
IndiceFiguras = strcmp({DataVariablesWorkspace.class}, 'matlab.ui.Figure');

% Nombre de todas las figuras existentes en la workspace
NombreFiguras = {DataVariablesWorkspace(IndiceFiguras).name};

% Si la carpeta ya existe se le agrega un número para evitar
% sobre-escritura.
Path = preventFileOverwrite(Path);

% Se crea o vacía la carpeta de las figuras a guardar
mkdir(Path);

for i = 1:numel(NombreFiguras)
    
    % Se ensambla un comando de Matlab en la forma de un string (Forma:
    % Handle(1)). Luego, con el comando "evalin" se evalúa el string y se
    % guarda el output. Se utiliza "evalin" en lugar de "eval" para
    % ejecutar el comando en el workspace base donde están todas las
    % variables y figuras.
    HandleFigura = evalin('base', NombreFiguras{i} + ";");
    
    % Si el handle actual existe, entonces se guarda la figura como una
    % imagen PNG.
    if isvalid(HandleFigura)
        saveas(HandleFigura, Path + "\" + HandleFigura.Name + "." + Extension);
    end
end

end

