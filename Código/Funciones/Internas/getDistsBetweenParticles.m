function [DistsEntrePart] = getDistsBetweenParticles(Posicion_Actual, FormaMatriz)
% GETDISTSBETWEENPARTICLES Función que retorna todas las distancias
% existentes entre todas las combinaciones posibles de partículas en la
% forma de una matriz cuadrada triangular superior con dimensiones de 
% "NoParticulas" x "NoParticulas".
% -------------------------------------------------------------------------
% Input: 
%   - Posicion_Actual: Posición actual de las partículas. Cada columna de 
%     la matriz debe corresponder a las coords. (X,Y) de las partículas. 
%     Dims = "NoParticulas" x 2
%   - FormaMatriz: Forma que tendrá la matriz de distancias retornada.
%     Existen dos opciones: "Triangular y "Full". Para "Triangular" se
%     retorna la matriz triangular superior sin distancias repetidas o 
%     distancias entre un punto y si mismo. En "Full" se retorna la matriz 
%     completa sin realizar el filtrado previamente especificado.
%
% Output: 
%   - DistsEntrePart: Distancias entre partículas. Cada fila y columna con 
%     el mismo index corresponde a una partícula. Por ejemplo: Fila = 
%     Columna = 1 corresponden a la partícula 1, Fila = Columna = 2 
%     corresponden a la partícula 2, etc. Entonces si se indexa la matriz 
%     como (1,2) o (2,1) se obtendrá la distancia entre la partícula 1 y 2. 
%
% ------------------------------------------------------------------------- 
% Ejemplo: 
%   Con 3 partículas, esta función inicialmente obtiene
%
%   DistsEntrePart =        P1    P2    P3
%                    P1 |  d11   d12   d13  |
%                    P2 |  d21   d22   d23  |
%                    P3 |  d31   d32   d33  |
%
%   Debido a que la distancia entre una partícula y si misma es 0, la
%   matriz se puede reexpresar de la siguiente manera
%
%   DistsEntrePart =        P1    P2    P3
%                    P1 |   0    d12   d13  |
%                    P2 |  d21    0    d23  |
%                    P3 |  d31   d32    0   |
%
%   Las distancias d21, d31 y d32 son réplicas de d12, d13 y d23 entonces
%   si "FormaMatriz" = 'Triangular' se elimina la redundancia eliminando la 
%   sección triangular inferior de la matriz usando "triu()". De lo
%   contrario si se utiliza "FormaMatriz" = 'Full', se retorna la matriz
%   en el estado del ultimo paso descrito.
%
%   DistsEntrePart =        P1    P2    P3
%                    P1 |   0    d12   d13  |
%                    P2 |   0     0    d23  |
%                    P3 |   0     0     0   |
%
%   Finalmente, para evitar cualquier problema al momento de introducir la
%   matriz en la función "SolveCollisions()" todos los ceros de la matriz
%   se convierten en NaN's.
%
%   DistsEntrePart =        P1    P2    P3
%                    P1 |  NaN    d12   d13  |
%                    P2 |  NaN    NaN   d23  |
%                    P3 |  NaN    NaN   NaN  |
%
% ------------------------------------------------------------------------- 

    NoParticulas = size(Posicion_Actual,1);

    MatrizPosX = repelem(Posicion_Actual(:,1), 1, NoParticulas);   	% Coordenadas X de posición se repiten "NoParticulas" veces a la derecha 
    MatrizPosY = repelem(Posicion_Actual(:,2), 1, NoParticulas);   	% Coordenadas Y de posición se repiten "NoParticulas" veces a la derecha 
    DifPosX = MatrizPosX - Posicion_Actual(:,1)';                 	% A cada fila de las coordenadas X/Y "repetidas" se le restan las posiciones X/Y actuales en fila.
    DifPosY = MatrizPosY - Posicion_Actual(:,2)';                	% Hecho para obtener la diferencia de posición X/Y entre todas las combinaciones posibles de partículas
    
    DistsEntrePart = sqrt(DifPosX .^2 + DifPosY .^2);               % Todas las distancias existentes entre partículas. Matriz de "NoParticulas" x "NoParticulas"
    
    switch FormaMatriz
        case "Triangular"
            DistsEntrePart = triu(DistsEntrePart);                  % La data por encima y debajo de la diagonal son duplicados de los mismos datos. Se elimina el "triangulo" inferior.
            Mascara = triu(ones(NoParticulas),1);                   % Matriz cuadrada de unos de NoParticulas x NoParticulas. La sección triangular inferior (Incluyendo la diagonal) se iguala a 0
            Mascara(Mascara == 0) = NaN;                        	% Los ceros de la matriz de máscara se reemplazan por NaN's
            DistsEntrePart = Mascara .* DistsEntrePart;           	% Para ignorar las distancias entre una partícula y si misma, y las distancias redundantes, se le aplica la máscara a la matriz de distancias
    
        case "Full"
            % Se mantiene la matriz igual 
            
    end
end

