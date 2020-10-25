function [OutputString] = strArray2singleStr(InputArray)
% STRARRAY2SINGLESTR Convierte un array de strings en un único string 
% que incluye cada elemento en el array, cada uno separado por el caracter
% "/". 
% -------------------------------------------------------------------------
%
% Ejemplo: 
%   InputArray = ["Hola" "Adios"];
%   OutputString = strArray2singleStr(InputArray);
%   OutputString = "Hola / Adios"
%
% -------------------------------------------------------------------------
    
    % "OutputString" se inicializa con el primer valor del array
    if ~isempty(InputArray)
        OutputString = InputArray(1);
    else
        error("Error: El array ingresado en la función está vacío");
    end
    
    % Si el número de elementos en el "InputArray" es mayor a 1
    if numel(InputArray) > 1
        
        % Se revisa cada elemento adicional del array de entrada y se
        % concatena al output string colocando el separador "/".
        for i = 2:numel(InputArray)
            OutputString = OutputString + " / " + InputArray(i);
        end
        
    end
            
end

