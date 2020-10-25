function E = initE(E)

% Precomputes the relationship between cartesian coordinates and
% sines / cosines for use in m2c() and some other useful precomputations
% TODO add dimension checks


% --- structural values of the mechanical system (defaults)

D.radii       = 0.1*[7 2; 7 2; 7 4];   % [n  2] matrix of major and minor radii
                                       % major must be larger than minor
                                       
D.masses      = pi*sum(D.radii.^2,2);  % [n  1] vector of capsule masses

D.mechanisms  = [1 1 2]';              % [n  1] vector of mechanism indexes of each capsule 
                                       % all the capsules in the same mechanism are connected
                                       % nf = max(E.mechanisms) is the total number of mechanisms
                                       
D.anchors     = [0 0 1; nan nan nan];  % [nf 3] matrix of the anchors of each mechanism
                                       % first two numbers are the cartesian location of
                                       % the anchor, while the third is the location of
                                       % the anchor on the major axis of the first capsule
                                       % of the mechanism (in normalized units).
                                       % use nans for floating (unanchored) mechanisms.

D.joints      = [1  2];                % [nj 2] matrix which specifies which capsules are connected

D.j_locs      = [1 -1];                % [nj 2] matrix which specifies where on the capsules are
                                       % the joints, on the major axes (in normal units).
                                       
D.j_constr    = 1;                     % vector indexing into (1:nj) specifying joint limits

D.a_constr    = 1;                     % vector indexing into (1:n) specifying 
                                       % absolute rotation limits

D.a_lims      = [-pi/2  pi/2;-4*pi/5 -pi/5]; % [nj+na 2] joint and anchor limits (concatenated)
                                       
D.collidable  = logical([0 0 0; 0 0 1; 0 0 0]); % [n n] upper triangle of logical specifiying which
                                                % capsules can collide

D.walls       = [0 1 -5];              % [nw 3] wall positions. first two numbers specify the 
                                       % direction of the wall, the third one specifies
                                       % where the wall is on that axis relative to the
                                       % origin, so [0 1 3] is a floor at y==3
            
% --- global values for the simulator (defaults)
D.use_sparse   = 0;                    % should mass matrices and Jacobians be computed as 
                                       % sparse (1) or full (0) matrices
D.dt           = 0.01;                 % time step size
D.k_drag       = 1;                    % linear drag which the capsules experience
D.k_grav       = [0 -10 0];            % direction of gravity [x y theta]
D.k_fric       = 0.3;                  % friction coefficient
D.margin       = 1e-5;
D.friction_model  = 1;                 % 1: anitescu convex;  2: anitescu and potra
D.solver       = 1;                    % 1: my solver;  2: PATH
D.RK           = 0;                    % use Runge Kutta 4 rather than Euler
D.skin         = 0;                    % skin depth
D.stretch      = 1;                    % time strech   
D.draw_order   = 1:length(D.masses);   % draw order for graphics


if nargin == 0
   E  = struct(); % empty structure - use defaults
end
E           = setOpts(D,E);

n           = length(E.masses);
nf          = max(E.mechanisms);

ang_m       = logical([]);
ang_mx      = logical([]);
ang_my      = logical([]);
ang_p       = logical([]);
offsets     = sparse(0,2);
for i=1:nf
   angs  = find(E.mechanisms == i);
   ni    = size(angs,1);
   if ~isnan(E.anchors(i,:))
      ang_m  = [ang_m; true(ni,1)];
      ang_mx = [ang_mx; true(ni,1)];
      ang_my = [ang_my; true(ni,1)];      
      ang_p  = [ang_p; true(ni,1)];
      offsets(angs,:) = ones(ni,1)*E.anchors(i,1:2);
   else
      ang_m  = [ang_m; [false; false]; true(ni,1)];
      ang_mx = [ang_mx; [true; false]; true(ni,1)];
      ang_my = [ang_my; [false; true]; true(ni,1)];      
      ang_p  = [ang_p;  false;         true(ni,1)];
      offsets(angs,:) = zeros(ni,2);
   end
end
nm          = size(ang_m,1);
E.nm              = nm;
P           = sparse(0,0);

j_counter   = 0;

for i=1:nf
   mech_i = find(E.mechanisms == i);
   n_i      = length(mech_i);
   Q        = sparse(n_i,n_i);
   if ~isnan(E.anchors(i,:))
      Q(1,1)   = 1;
      A        = sparse(n_i,n_i);
      A(1,1)   = sum(E.radii(mech_i(1),1:2),2)*E.anchors(i,3);
      for j=1:n_i-1
         j_counter   = j_counter + 1;
         ab          = E.joints(j_counter,:) - mech_i(1) + 1;
         Q(j+1,ab)   = [-1 1];
         A(j+1,ab)   = sum(E.radii(mech_i(ab),1:2),2)'.*E.j_locs(j_counter,:).*[1 -1];
      end
   else
      Q(1,:)   = E.masses(mech_i)';
      A        = sparse(n_i,n_i+1);
      A(1,1)   = sum(E.masses(mech_i));
      for j=1:n_i-1
         j_counter   = j_counter + 1;
         ab          = E.joints(j_counter,:) - mech_i(1) + 1;
         Q(j+1,ab)   = [-1 1];
         A(j+1,ab+1) = sum(E.radii(mech_i(ab),1:2),2)'.*E.j_locs(j_counter,:).*[1 -1];
      end
   end
   p     = Q\A;
   P     = [P sparse(size(P,1),size(p,2)); sparse(size(p,1),size(P,2)) p];
end

% --- precompute angle constraint Jacobian
nj                = size(E.j_constr,1);
n2m               = find(ang_m);
ja                = E.joints(E.j_constr,:);
ja                = n2m(ja);
Ja                = sparse(ja',[1;1]*(1:nj),[1; -1]*ones(1,nj),nm,nj);

na                = size(E.a_constr,1);
ja                = n2m(E.a_constr);
Ja                = [Ja sparse(ja,(1:na),ones(1,na),nm,na)];

% --- cartesian mass matrix
M                 = [E.masses'; E.masses'; E.masses'.*([13 7]*E.radii'.^2/12)];
M                 = sparse(1:3*n,1:3*n,M(:));

% --- elliptical tranform constants and indexing for constraint bookkeeping
rf                = [atanh(E.radii(:,2)./E.radii(:,1)) sqrt(E.radii(:,1).^2-E.radii(:,2).^2)];
coll              = triu(double(E.collidable),1);
coll(coll~=0)     = 1:nnz(coll);
coll              = sparse(coll);

% --- basic constants
E.n               = n;                 % number of capsules
E.nf              = nf;                % number of mechanisms
E.na              = size(Ja,2);        % number of angle constraints
E.nw              = size(E.walls,1);   % number of wall constraints (walls)
E.nc              = nnz(E.collidable); % number of possible e-e collision pairs

% --- indexing constants for full_x0 (i.e. [x; lambda])
E.w_offset       = E.nm + E.na;            % index of the first wall constraint
E.c_offset       = E.nm + E.na + 2*E.nw*E.n;     % index of the first collision constraint
E.n_total        = E.nm + E.na +...        % total number of unknowns in the LCP
                  (E.nc + 2*E.nw*E.n)*(1 + (E.k_fric>0)*(2*E.friction_model-1));
%                   (E.nc + E.nw*E.n)*2*E.friction_model;
                          
% --- make ijvT
if E.use_sparse
   Pix               = P;
else
   Pix               = ones(size(P));
end
nzP               = nnz(Pix);
Pix(Pix~=0)       = 1:nzP;
T                 = sparse(3*n,nm);
T(1:n,ang_mx)     = Pix;
Pix(Pix~=0)       = (1:nzP)+nzP;
T(n+1:2*n,ang_my) = Pix;
T(2*n+1:end,ang_m)= sparse(1:n,1:n,2*nzP + (1:n));

lix               = reshape(1:3*n,[n 3])';
T                 = T(lix(:),:);
[iT,jT,vT]        = find(T);

% --- make ijvTx
if E.use_sparse
   Pix               = P;
else
   Pix               = ones(size(P));
end
Pix               = Pix(:,ang_p);
nzP               = nnz(Pix);
Pix(Pix~=0)       = 1:nzP;
Tx                = sparse(3*n,nm);
Tx(1:n,ang_m)     = Pix;
Pix(Pix~=0)       = (1:nzP)+nzP;
Tx(n+1:2*n,ang_m) = Pix;
Tx                = Tx(lix(:),:);
[iTx,jTx,vTx]     = find(Tx);                  
                  
% convert to full representation if ~use_sparse
if E.use_sparse
   E.P               = P;
   E.ijvT            = [iT  jT  vT];
   E.ijvTx           = [iTx jTx vTx];
else
   E.P               = full(P);
   E.ixT             = iT+3*n*(jT-1);
   E.vT              = vT;
   E.ixTx            = iTx+3*n*(jTx-1);
   E.vTx             = vTx;
end

% put all relevant constants in E
E.ang_p           = ang_p;
E.ang_m           = ang_m;
E.offsets         = offsets;
E.collidable      = coll;
E.Ja              = Ja;
E.rf              = rf;
E.M               = M;

