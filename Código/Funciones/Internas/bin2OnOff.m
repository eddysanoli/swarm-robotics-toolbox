function [outputStr] = bin2OnOff(ValorBinario)
% BIN2ONOFF Función que toma un valor binario y retorna un string igual a 
% "On" cuando el binario es 1 y "Off" cuando el binario es 0.
% -------------------------------------------------------------------------
% Inputs:
%   - ValorBinario: Valor binario a convertir a string
%
% Outputs:
%   - outputStr: String de salida. Según el valor binario puede ser "On",
%     "Off" o "Unknown" en caso el valor no sea binario.
%
% -------------------------------------------------------------------------

    if ValorBinario == 1
        outputStr = "On";
        
    elseif ValorBinario == 0
        outputStr = "Off";
        
    else
        outputStr = "Unknown";
    end
    
end

