function [xnew,vnew,lambda,cp]   = dynamics(x,v,u,E)

[xnew,vnew,lambda,cp]   = dyn(x,v,u,E);

if E.RK
   x1    = xnew - x;
   v1    = vnew - v;

   [x2,v2,l2]   = dyn(x+.5*x1,v+.5*v1,u,E);
   x2    = x2 - (x+.5*x1);
   v2    = v2 - (v+.5*v1);
   
   [x3,v3,l3]   = dyn(x+.5*x2,v+.5*v2,u,E);
   x3    = x3 - (x+.5*x2);
   v3    = v3 - (v+.5*v2);
   
   [x4,v4,l4]   = dyn(x+x3,v+v3,u,E);
   x4    = x4 - (x+x3);
   v4    = v4 - (v+v3);
   
   xnew     = x + (x1+x4)/6 + (x2+x3)/3;  
   vnew     = v + (v1+v4)/6 + (v2+v3)/3;  
   lambda   = (lambda+l4)/6 + (l2+l3)/3;
end



function [xnew,vnew,lambda,cp]   = dyn(x,v,u,E)

% initialize basic constants
dt             = E.stretch*E.dt;
n              = E.n;
nm             = E.nm;

% indexing constants into full_x0 (i.e. [x; lambda])
w_offset       = E.w_offset;
c_offset       = E.c_offset;

% minimal to cartesian transformation and its derivatives
[xc,T,Tx,Txx]  = m2c(x,E); 

% coriolis force and Jacobians
Mx             = T'*E.M*Tx;
c              = -Mx*(v.^2);
cv             = -2*v(:,ones(nm,1))'.*Mx;
cx             = -v(:,ones(nm,1))'.^2 .* (T'*E.M*Txx);
cx             = cx - diag(sum(cx,2));

% drag Jacobian
cs             = [cos(x(E.ang_m)'); sin(x(E.ang_m)')];
dr_i           = bsxfun(@plus,[1 2 1 2 3]',3*(0:n-1));
dr_j           = bsxfun(@plus,[1 1 2 2 3]',3*(0:n-1));
er             = [1 1;0 1]*E.radii';  % effective radii
dr_v           = -2*E.k_drag*[sum(er([2 1],:).*cs.^2);...
                        [1;1]*(([-1 1]*er).*prod(cs));...
                        sum(er.*cs.^2);...
                        er(1,:).^3/6];
dragx          = T'*sparse(dr_i,dr_j,dr_v)*T;

% mass matrix 
M              = T'*E.M*T;
Mi             = M  - dt*cv - dt^2*cx - dt*dragx;

% force vector
gravity        = E.k_grav'*E.masses';
F              = c  - cv*v + T'*(u+gravity(:));
q              = M*v+F*dt;  

% velocity-dependent collision margins
margins        = reshape(T*v,size(xc))*dt;
margins        = sqrt(sum(abs(margins.*[ones(2,n); sum(E.radii,2)']).^2)) + E.margin;

% angle constraints and Jacobian
[ka,Ja]        = angle_constraints(x, E.Ja, E.a_lims);

% wall and collision constraints, with or without friction
if E.k_fric > 0
   [kw,Jw,ixw,Jwf]   = wall_constraints(xc, E.radii, E.walls, margins);
   [kc,Jc,ixc,cp,Jcf]= collision_constraints(xc, E.radii, E.collidable, margins);
   Jf = [Jwf Jcf];
else   
   [kw,Jw,ixw]       = wall_constraints(xc, E.radii, E.walls, margins);
   [kc,Jc,ixc,cp]    = collision_constraints(xc, E.radii, E.collidable, margins);  
   Jf                = zeros(3*n,0);
end
Jw             = T'*Jw;
Jf             = T'*Jf;
Jc             = T'*Jc;

% indexes (into xo_full) of active variables 
ixw            = ixw + w_offset;
ixc            = ixc + c_offset;
ix             = [(1:nm+size(Ja,2))'; ixw; ixc];

% new velocity (and constraint forces)
[vlambda,J,ix]    = do_LCP(Mi, Ja, [Jw Jc], Jf, [-q; ka/dt; kw/dt; kc/dt], ix, E);
% vnew           = vlambda(1:nm);
lambda         = vlambda(nm+1:end);
% if E.skin > 0
%    cskin = 1 - exp(-.5*(lambda/E.skin).^2);
% else
   cskin = 1;
% end
vnew           = Mi \ (q + J*(cskin.*lambda));

% new state
xnew           = x + E.dt*vnew;
vnew           = v + (vnew-v)/E.stretch;

% multipliers (sparse)
vl_s           = sparse(E.n_total,1);
vl_s(ix)       = vlambda;
lambda         = full(vl_s(nm+1:end));


function [k,J] = angle_constraints(x,Ja,a_lims)
n_a            = size(Ja,2);
phi            = wrap(Ja'*x);
% phi            = Ja'*x;
% thresh         = 2*(phi < 0.5*a_lims*[1;1])-1;
[dum,thresh]   = min(abs(wrap([phi phi]-a_lims)),[],2); 
thresh         = 3-2*thresh;                        % -1: closer to upper limit; 1: closer to lower limit
% dir            = 2*(a_lims(:,2) > a_lims(:,1))-1;   % -1: internal allowed     ; 1: external allowed
J              = Ja*sparse(1:n_a,1:n_a,thresh,n_a,n_a);
k              = wrap(phi - a_lims((1:n_a)'-n_a*(thresh-1)/2)).*thresh;


function [k,J,ixw,Jf] = wall_constraints(xc, radii, walls, margins)
n        = size(xc,2);
nw       = size(walls,1);

if nw > 0   
   % preallocate
   Jv       = zeros(3,2*n,nw);

   % initialize
   x        = xc(1:2,:);                     % [2   n] capsule origins
   a        = xc(3,:);                       % [2   n] capsule angles
   
   % distances
   av       = [cos(a); sin(a)];              % [2   n] capsule directions
   rp       = radii(:,[1 1])'.*av;           % [2   n] vectors to sphere centers
   p        = [x+rp  x-rp];                  % [2 2*n] sphere centers [first second]
   k        = walls*[p;-ones(1,2*n)]-...     % [1 2*n] distances to wall of sphere centers 
              ones(nw,1)*radii([1:n 1:n],2)';%         minus radii

   % Jacobians in [3 2*n nw] TODO: move all this to after distance
   % calculation if it seems that it hurts in CPU time
   rw       = bsxfun(@times, p23(-walls(:,1:2)'), radii([1:n 1:n],2)');
                                             % [2 2*n nw] vectors from centers to nearest point
   rel      = bsxfun(@plus, [rp -rp], rw);   % [2 2*n nw] vectors from origins to nearest point
   N        = permute(walls(:,1:2,ones(1,2*n)), [2 3 1]); % permuted wall directions
   Jv(1:2,:,:) = N;                          % first 2 rows are just wall directions
   Jv(3,:,:)= sum([-rel(2,:,:); rel(1,:,:)] .* Jv(1:2,:,:),1); % third row requires cross product
   Jv       = reshape(p23(Jv),[3*nw 2*n]);   % reshape to [3*nw 2*n]
   
   % find relevant collisions
   close    = k < margins(ones(nw,1),[1:n 1:n]); 
   ac       = find(close);
   ac       = ac(:);
   [aci,acj]= find(close);
   acj      = acj - n*(acj>n); % second spheres are on the same capsule
   na       = length(ac);
   k        = k(ac);
   k        = k(:);
   
   % form Jacobian
   cols     = [1;1;1]*(1:na);
   rows     = bsxfun(@plus,[1 2 3]',(acj'-1)*3);
   Jvix     = bsxfun(@plus,[1 2 3]',(ac' -1)*3);
   J        = sparse(rows(:),cols(:),Jv(Jvix),3*n,na);
   ixw      = ac;
   
   if nargout == 4
      Jfv            = zeros(3,2*n,nw);
      Jfv(1:2,:,:)   = [-N(2,:,:); N(1,:,:)];
      Jfv(3,:,:)     = sum(rel .* N,1);
      Jfv            = reshape(p23(Jfv),[3*nw 2*n]);
      Jf             = sparse(rows(:),cols(:),Jfv(Jvix),3*n,na);
   end
   
else
   J        = sparse([],[],[],3*n,0);
   Jf       = sparse([],[],[],3*n,0);
   k        = [];
   ixw      = [];
end

function [k,J,ixc,x,Jf] = collision_constraints(xc, radii, collidable, margins)
nc       =  nnz(collidable);
[e1,e2]  = find(collidable);

if nc > 0
   cl_pairs = sum((xc([1 2],e1) - xc([1 2],e2)).^2,1)' < (margins(e1)'+margins(e2)'+sum(radii(e1,:),2)+sum(radii(e2,:),2)).^2;
   na       = sum(cl_pairs);
   e1       = e1(cl_pairs);
   e2       = e2(cl_pairs);
else
   na     = 0;
end

if na > 0
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
   torques  = [1 1 0 0;0 0 1 1]*...                % [2 na] cross product 
               ([[0 -1;1 0]*sr; [0 1;-1 0]*sr].*rel);
   Jv       = [-sr; torques(1,:);...               % [6 na] Jacobian values [sources; targets]
                sr; torques(2,:)]; 
   Jv(:,i>2)= Jv([4:6 1:3]',i>2);                  % [6 na] Jacobian values [e1; e2]
   
   rows              = [bsxfun(@plus,e1*3-2,[0 1 2])'; bsxfun(@plus,e2*3-2,[0 1 2])'];
   cols              = [1;1;1;1;1;1]*(1:na);
   J                 = sparse(rows(:),cols(:),Jv,numel(xc),na);
   ixc               = collidable(e1 + size(collidable,1)*(e2-1));
   x                 = [sc(1:2,:) sc(3:4,:)]';
   
   if nargout == 5   
      torques     = [1 1 0 0;0 0 1 1]*...           % [2 na] cross product 
                     ([sr; -sr].*rel);
      Jfv         = [[0 -1;1 0]*sr; torques(1,:);...% [6 na] Jacobian values [sources; targets]
                     [0 1;-1 0]*sr; torques(2,:)]; 
      Jfv(:,i>2)  = Jfv([4:6 1:3]',i>2);            % [6 na] Jacobian values [e1; e2]
      Jf          = sparse(rows(:),cols(:),Jfv,numel(xc),na);
   end   
  
else
   J        = sparse([],[],[],numel(xc),0);
   Jf       = sparse([],[],[],numel(xc),0);
   k        = [];
   ixc      = [];
   x        = zeros(0,2);
end


function d = wrap(x)

% d = mod(x+pi,2*pi)-pi;

Z  = (x>pi).*(x-2*pi)+(x<-pi).*(x+2*pi);
d  = Z+x.*~Z;

