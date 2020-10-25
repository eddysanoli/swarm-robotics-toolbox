function drawFrame(axis, E, xc, c_points, cursor, info)

persistent G

fig   = get(axis,'parent');

if isempty(G) || G.axis ~= axis || ~ishandle(G.lines)
   G.axis   = axis;
   
   set(fig,'CurrentAxes',axis);
   
   set(axis,...
      'Xtick', [],...
      'Ytick', [],...
      'box', 'on',...
      'PositionConstraint', 'innerposition',...
      'Xlim', [-5 5],...
      'Ylim',[-5 5],...
      'DataAspect',[1 1 1],...
      'tag', 'simulation'); 

   G.lines = patch('CData', [],...
                   'CDataMapping','scaled',...
                   'EdgeColor', [0.1 0.1 0.5],...
                   'FaceColor',[0.7 0.7 0.8],...
                   'EdgeAlpha', 0.5,...
                   'LineWidth', 1,...
                   'tag', 'shape');

   G.collisions   = line('Xdata',[],...
                         'Ydata',[],...
                         'Color','r',...
                         'Marker','o',...
                         'LineStyle','none',...
                         'MarkerSize',3);             
             
   G.curs  = patch('EdgeColor', [0.8 0.15 0.15],...
                   'FaceColor', [0.8 0.15 0.15],...
                   'EdgeAlpha', 0.4,...
                   'LineWidth', 1); 

   G.info = text(-4.8,4.5,'');
   
   set(fig,'Renderer','painters')
end

n           = length(E.masses);
if isempty(c_points)
   c_points = zeros(0,2);
end
nc          = 100;
oc          = ones(nc,1);
circ        = [linspace(-pi/2, pi/2, nc/2) linspace(pi/2, 3*pi/2, nc/2)];
circ        = cos(circ) + 1i*sin(circ);

% capsules
coords   = E.radii(:,2)*circ(1,:) + E.radii(:,1)*[ones(1,nc/2) -ones(1,nc/2)];
xz       = xc(1:2,:)'*[1;1i];
coords   = exp(1i*xc(3*oc,:)').*coords + xz(:,oc);
% set(lines1,'Xdata',real(coords)','Ydata',imag(coords)');
cdo      = coords(E.draw_order,:).';
set(G.lines,'Xdata',real(cdo),'Ydata',imag(cdo));

if strcmp(get(fig,'Renderer'),'OpenGL')
    set(G.lines,'Zdata',oc*linspace(-2,-1,n)*1e-3);
end

% collision points
set(G.collisions,'Xdata',c_points(:,1),'Ydata',c_points(:,2));

% cursor line
if ~isempty(cursor)
   set(G.curs,'Xdata',cursor(1,:),'Ydata',cursor(2,:),'Zdata',-0.5e-3*ones(2),'Visible','on');
else
   set(G.curs,'Visible','off');
end

% text
set(G.info,'String',info)