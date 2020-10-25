function [XVerts,YVerts,ZVerts] = polyshape2fill3(CoordsX,CoordsY,CoordsZ)
% POLYSHAPE2FILL3 Función que cambia el formato de los vértices de un
% polígono destinado para ser utilizado en funciones como polyshape
% (Vértices en una sola columna separando con NaN cada objeto) a vértices
% que pueden ser utilizados en funciones como fill3 (Vértices donde los
% vértices correspondientes a diferentes objetos están en diferentes
% columnas).
% -------------------------------------------------------------------------
% Input
%   - XVerts: Vector columna con las coordenadas X de los vértices 
%     correspondientes a uno o más polígonos. En formato "polyshape()"
%   - YVerts: Vector columna con las coordenadas Y de los vértices 
%     correspondientes a uno o más polígonos. En formato "polyshape()"
%
% Output
%   - XVerts: Vector columna con las coordenadas X de los vértices 
%     correspondientes a uno o más polígonos. En formato "fill3()"
%   - YVerts: Vector columna con las coordenadas Y de los vértices 
%     correspondientes a uno o más polígonos. En formato "fill3()"
%   - ZVerts: Vector columna con las coordenadas Z de los vértices 
%     correspondientes a uno o más polígonos. En formato "fill3()"
%
% -------------------------------------------------------------------------

    XVerts = [];
    YVerts = [];
    Objeto = 1;
    Punto = 1;
    Vert = 1;
    while Punto <= size(CoordsX,1)

        if isnan(CoordsX(Punto,1))
            Objeto = Objeto + 1;
            Vert = 1;
        else
            XVerts(Vert,Objeto) = CoordsX(Punto,1);
            YVerts(Vert,Objeto) = CoordsY(Punto,1);
            Vert = Vert + 1;
        end

        Punto = Punto + 1;

    end

    NoObjetos = size(XVerts,2);
    NoPuntos = size(XVerts,1);
    XVerts = repmat(XVerts,1,2);
    YVerts = repmat(YVerts,1,2);
    
    AlturaBase = CoordsZ(1,1);
    AlturaTapa = CoordsZ(1,2);
    ZVerts = [repmat(AlturaBase*ones(NoPuntos,1),1,NoObjetos) ... 
              repmat(AlturaTapa*ones(NoPuntos,1),1,NoObjetos)];

end

