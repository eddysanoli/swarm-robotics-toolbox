function [X,L] = simulate(E,S)

% default values
nm          = E.nm;              % number of state variables
D.x0        = [2*randn(nm,1);... % initial states
             0.1*randn(nm,1)];   
D.N         = inf;               % final time
D.policy    = @(x) x;            % policy (controller)
D.graphs    = 0;                 % draw graphs ?
D.frames    = 1;                 % draw frames (simulation) ?
D.spring    = 20;                % spring constant
D.p_steps   = 5;                 % constraint projection steps
D.c_points  = 0;                 % draw collision points?

if nargin == 1
   S  = struct(); % empty structure - use defaults
end

S           = setOpts(D,S);

% --- initial state
x           = S.x0(1:E.nm);
v           = S.x0(E.nm+1:end);


% --- constants
n           = length(E.masses);

% --- graphics
G.fig = findobj(0,'name','CapSim');
if  isempty(G.fig)
   G.fig = figure();
end
figure(G.fig);
clf;

if 0 %OpenGl rarely works well
   rend = 'OpenGL';
else
   rend = 'Painters';
end
set(G.fig,...
   'Color','white',...
   'Renderer', rend,...
   'MenuBar', 'figure',...
   'WindowButtonDownFcn', @fDown,...
   'WindowButtonUpFcn', @fUp,...
   'KeyPressFcn', @fKey,...
   'NumberTitle', 'off',...
   'Name', 'CapSim');
colormap bone;

if S.graphs
   G.ax1 = subplot(2,3,[1 2 4 5]);
   G.ax2  = subplot(2,3,3);
   set(G.ax2,'box', 'on'); 
   G.ax3  = subplot(2,3,6);
   set(G.ax3,'box', 'on'); 
else
   G.ax1 = axes();
end
setappdata(G.fig,'Stop',0);

% --- counters
time        = 0;
i_time      = 0;
X           = [];
L           = [];
It          = [];

while ~getappdata(G.fig,'Stop') && (time <= S.N)
   [xc,J]      = m2c(x,E);
   
   % get spring force
   cp = getappdata(G.fig,'cursorPos');
   u  = zeros(3*n,1);
   if ~isempty(cp)
      if isnan(w)
         % find nearest point on nearest capsule
         [w,rel] = nearest(xc, E.radii, cp);
      end
      xr             = [cos(xc(3,w)) -sin(xc(3,w)); sin(xc(3,w)) cos(xc(3,w))]*rel;
      xw             = xc(1:2,w) + xr;
      cursor         = [cp' xw];
      xf             = cp'-xw;
      u(3*w-2:3*w)   = D.spring*[xf; xf'*[0 -1;1 0]*xr];
   else
      cursor         = [];
      w              = nan;
   end
   
   % calculate info data
   energy            = 0.5*full(v'*J'*E.M*J*v);
   info              = sprintf('Energy: %-6.3g\nTime:  %-4.1fms',energy,1000*i_time);


   % integrate
   tic;
   [x,v,lam,c_points]   = dynamics(x,v,u,E);
   
   % time measurement
   i_time               = toc;
   if time < S.p_steps % move to right place
      v = zeros(size(v));
   end   
   
   % draw collision points?
   if ~S.c_points
      c_points = zeros(0,2);
   end
   
   % draw (previous) state
   drawFrame(G.ax1, E, xc, c_points, cursor, info);   
   
   % save traces
   X           = [X [x;v]];
   L           = [L lam];
   It          = [It i_time];

   if S.graphs
      if size(X,2) > 1
         tspan = max(1,size(X,2)-round(8/E.dt)):size(X,2);
         set(G.fig,'currentaxes',G.ax2);      
         plot(X(1:size(x,1),tspan)');
         set(G.ax2,'Xtick',[],'Ytick',[],'Xlim',[1 length(tspan)]);
         set(G.fig,'currentaxes',G.ax3);      
         plot(L(:,tspan)');
%          set(G.ax3,'Xtick',[],'Ytick',[],'Xlim',[1 length(tspan)]);
         set(G.ax3,'Xtick',[],'Xlim',[1 length(tspan)]);
         set(G.fig,'currentaxes',G.ax1);
      end
   end
   
   drawnow;
   time = time+1;
end

fprintf('Average dynamics time: %-4.1fms\n',1000*mean(It));

function [w, rel] = nearest(xc, radii, cp)
n        = size(xc,2);
xc       = [xc [cp'; 0]];
radii    = [radii; 0 0];
na       = n;
[e1,e2]  = deal((1:n)',(n+1)*ones(n,1));

z        = zeros(8,4); 
z([1:2:8;2:2:8]+8*[0:3;0:3]) = 1;
z        = z';

r        = radii';                              % [2  n] radii
x        = xc(1:2,:);                           % [2  n] center-of-mass positions
a        = xc(3,:);                             % [1  n] angles           

v        = [cos(a); sin(a)];                    % [2  n] unit vectors along capsule axes
p        = [x+r([1 1],:).*v;  x-r([1 1],:).*v]; % [4  n] end points of segments [x1 y1 x2 y2]'

pp       = [p(:,e1); p(:,e2)];                  % [8 na] segment endpoint pairs      [p1; p2]
xx       = [x([1 2 1 2],e2); x([1 2 1 2],e1)];  % [8 na] target segment centers      [x2; x1] 
vv       = [v([1 2 1 2],e2); v([1 2 1 2],e1)];  % [8 na] target segment unit vectors [v2; v1]
rr1      = [r([1 1],e2); r([1 1],e1)];          % [4 na] first radii  [r1 r1 r2 r2]'
rr2      = [r([2 2],e2); r([2 2],e1)];          % [4 na] second radii [r1 r1 r2 r2]'

t        = z*((pp - xx).*vv);                   % [4 na] two offset scalars for each pair 
t        = min(rr1, max(-rr1,t));               % [4 na] clamp the offset scalars to segment ends
uu       = xx + vv.*t([1 1 2 2 3 3 4 4],:);     % [8 na] closest point candidates on target segments
d        = z*((uu-pp).^2);                      % [4 na] distance to candidates
[l,i]    = min(d,[],1);                         % find closest point-pair
ax       = i   + 4*(0:na-1);                    % indexes to the sources
bx       = 5-i + 4*(0:na-1);                    % indexes to the targets
ix       = [2*i-1; 2*i]+[8;8]*(0:na-1);         % indexes to the closest pair sources
jx       = [2*(5-i)-1; 2*(5-i)]+[8;8]*(0:na-1); % indexes to the closest pair targets
s        = [pp(ix); uu(ix)];                    % [4 na] [sources; targets] on segments
sr       = uu(ix) - pp(ix);                     % [2 na] from sources to targets (on segments)
sr       = sr .* ([1 1]'*sum(sr.^2,1).^(-.5));  % [2 na] normalize the direction
dir      = sign(sum(sr.*(xx(ix)-xx(jx)),1));    % [1 na] sign correction in case of penetration
sr       = sr .* dir([1 1],:);                  % [2 na] apply the correction
rr3      = [[1 1]'*rr2(bx); [1 1]'*rr2(ax)];    % [4 na] select the right radii
sc       = s + [sr; -sr].*rr3;                  % [4 na] [sources; targets] on capsule surfaces
scr      = sc([3 4],:) - sc([1 2],:);           % [2 na] from sources to targets (on capsule surface)
k        = sum(scr.*sr,1)';                     % [na 1] project on direction to get distance

rel      = sc - [xx(jx); xx(ix)];               % [4 na] from centers to [sources; targets]
rel(:,i>2)= rel([3:4 1:2]',i>2);                % [4 na] reorder to [e1; e2]

[dum,w]  = min(k);                              % closest capsule
rel      = expm([0 1;-1 0]*a(w))*rel(1:2,w);    % rotate rel to egocentric coordinates



function fDown(src, evnt)
axis  = findobj(src, 'tag', 'simulation');
cp    = get(axis, 'CurrentPoint');  
cp    = cp(1, 1:2);
xlim  = get(axis, 'xlim');
ylim  = get(axis, 'ylim');
if cp(1) > xlim(1) && cp(1) < xlim(2) && cp(2) > ylim(1) && cp(2) < ylim(2)
   set(src, 'WindowButtonMotionFcn', @fMove);
   setappdata(src, 'cursorPos', cp);
end

function fMove(src, evnt)
h = findobj(src, 'tag', 'simulation');
cp = get(h, 'CurrentPoint');  
cp = cp(1, 1:2);
setappdata(src, 'cursorPos', cp); 
   
function fUp(src, evnt)
set(src, 'WindowButtonMotionFcn', '');
setappdata(src, 'cursorPos', ''); 

function fKey(fig, evnt)
if strcmp(evnt.Key, 'escape')
   setappdata(fig, 'Stop', 1);
end
