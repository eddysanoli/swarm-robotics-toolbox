function [Path] = preventFileOverwrite(Path)
% PREVENTFILEOVERWRITE Función que toma el path de un archivo o folder,
% revisa si el archivo existe y si este es el caso, modifica el path del
% archivo agregándole un número para prevenir la sobre-escritura del mismo.
% -------------------------------------------------------------------------
% Input:
%   - Path: String describiendo el path completo que apunta hacia un
%     archivo o carpeta.
%
% Output: 
%   - Path: Path corregido con un número agregado para evitar
%     sobre-escritura. En caso el archivo / folder no exista, se retorna el
%     mismo path inalterado.
%
% -------------------------------------------------------------------------
% 
% Ejemplo:
%
%   Path = ".\Output Media\Video\APF.mp4"
%   
%   Contenidos Folder:
%   - APF.mp4
%   - APF1.mp4
%   
%   if (Archivo ya existe)
%       Path = ".\Output Media\Video\APF2.mp4"
%   end
%
% -------------------------------------------------------------------------

% Se extrae el path base y la extensión del path ingresado
[PathBase,NombreArchivo,Extension] = fileparts(Path);
PathArchivo = PathBase + "\" + NombreArchivo;

% Número a agregar al final del nombre del archivo en caso ya exista el
% archivo.
Numero = 1;

% Si la carpeta ya existe se le agrega un número para evitar
% sobre-escritura.
while exist(PathArchivo + Extension,'file')
       
    % Si el número a agregar es igual o mayor a 2, entonces se elimina el
    % número adjunto al final del nombre del archivo. Si el número es 1
    % entonces se asume que el archivo no tiene dígito al final.
    if Numero > 1
        
        % Cantidad de dígitos del número anterior al actual (El número que
        % el archivo debería de tener).
        NoDigitos = numel(num2str(Numero - 1));
        
        % Se convierte el string a un char que puede ser indexado por el
        % usuario.
        PathArchivo = char(PathArchivo);
        
        % Se eliminan los digitos al final del path. Si por ejemplo, el
        % número al final del path es 10, entonces el número de dígitos es
        % 2. Si el path tiene 10 caracteres, queremos eliminar los últimos
        % dos. Entonces la indexación debería de ser: (end-1:end). Por eso
        % la fórmula "end-(NoDigitos-1):end". Para el caso anterior esto
        % esta fórmula retornaría la siguiente indexación "end-(2-1):end"
        % exactamente lo que se deseaba.
        PathArchivo(end-(NoDigitos - 1):end) = [];
    end

    % Se incrementa la cuenta del archivo y luego se agrega el siguiente
    % número en la secuencia en caso se requiera.
    PathArchivo = string(PathArchivo) + num2str(Numero);
  	Numero = Numero + 1; 
end

Path = PathArchivo + Extension;

end

