function [xc,T,Tx,Txx]  = m2c(x,E)
% Transforms the minimal representation x = [cm; theta] into the cartesian
% representation [x1;y1;theta1;...].
% xc is given in a [3 n] matrix for convenience
% T is the Jacobian of the transformation with size(T) = [3*n np]
% Tx is dT/dx which can be given in matrix form due to structure

nm             = E.nm;              % dimension of x
n              = E.n;               % number of ellipses
np             = size(E.ang_p,1);   % number of rows of z
nf             = sum(~E.ang_p);     % number of free mechanisms

cm             = x(~E.ang_m);
theta          = x(E.ang_m);
ct             = cos(theta);
st             = sin(theta);
z              = zeros(np,2);
z(E.ang_p,:)   = [ct st];
z(~E.ang_p,:)  = reshape(cm,[2 nf])';
xc             = [E.P*z+E.offsets theta]';
if nargout > 1
   if E.use_sparse
      Ct             = E.P(:,E.ang_p)*sparse(1:n,1:n,ct,n,n);
      St             = E.P(:,E.ang_p)*sparse(1:n,1:n,st,n,n);
      Pc             = E.P;
      Pc(:,E.ang_p)  = Ct;
      pc             = Pc(E.P~=0);
      Ps             = E.P;
      Ps(:,E.ang_p)  = -St;   
      ps             = Ps(E.P~=0);
      vT             = [ps; pc; ones(n,1)];
      T              = sparse(E.ijvT(:,1),E.ijvT(:,2),vT(E.ijvT(:,3)),3*n,nm);
      if nargout > 2
         pc             = Ct(E.P(:,E.ang_p)~=0);
         ps             = St(E.P(:,E.ang_p)~=0);     
         vT             = [-pc; -ps];
         Tx             = sparse(E.ijvTx(:,1),E.ijvTx(:,2),vT(E.ijvTx(:,3)),3*n,nm);
         if nargout > 3
            vT             = [ps; -pc];
            Txx            = sparse(E.ijvTx(:,1),E.ijvTx(:,2),vT(E.ijvTx(:,3)),3*n,nm);   
         end          
      end     
   else
      Ct             = E.P(:,E.ang_p).*ct(:,ones(1,n))';
      St             = E.P(:,E.ang_p).*st(:,ones(1,n))';
      Pc             = E.P;
      Pc(:,E.ang_p)  = Ct;
      Ps             = E.P;
      Ps(:,E.ang_p)  = -St;   
      vT             = [Ps(:); Pc(:); ones(n,1)];
      T              = zeros(3*n,nm);
      T(E.ixT)       = vT(E.vT);
      if nargout > 2    
         vTx            = [-Ct(:); -St(:)];
         Tx             = zeros(3*n,nm);
         Tx(E.ixTx)     = vTx(E.vTx);
         if nargout > 3
            vTxx           = [St(:); -Ct(:)];
            Txx            = zeros(3*n,nm);
            Txx(E.ixTx)    = vTxx(E.vTx);  
         end   
      end   
   end
end
