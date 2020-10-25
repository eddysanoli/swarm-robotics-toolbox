function [x,J,ix] = do_LCP(M, Ja, Jc, Jf, q, x0_index, E)

% --- init full_x0 if neccesary
persistent full_x0
if isempty(full_x0) || size(full_x0,1) ~= E.n_total || any(abs(full_x0) > 1e5) || any(isnan(full_x0))
   full_x0 = ones(E.n_total,1);
end

% --- construct LCP according to friction model
nm             = size(M,1);
if (E.k_fric == 0) || isempty(Jf)
   J              = [Ja Jc];
   nJ             = size(J,2);
   H              = [[M; J'] [-J; sparse(nJ,nJ)]];
   ix             = x0_index;   
else
   nc             = size(Jc,2);       
   if E.friction_model == 1     % Anitescu's convex friction model
      J              = [Ja Jc+E.k_fric*Jf Jc-E.k_fric*Jf];
      nJ             = size(J,2);
      H              = [[M; J'] [-J; sparse(nJ,nJ)]];
      q              = [q; q(end-nc+1:end,1)];      
      ixc            = x0_index(end-nc+1:end);
      ix             = [x0_index; ixc+nc];  
   else
      EE             = sparse(1:2*nc,[1:nc;1:nc],ones(1,2*nc),2*nc,nc);
      Mu             = E.k_fric*speye(nc);
      Jf             = [Jf -Jf];
      J              = [Ja Jc Jf(:,[1:nc; nc+1:2*nc])];
      na             = size(Ja,2);
      nc             = size(Jc,2);
      nj             = size(J,2);
      H              = [[M; J'; sparse(nc,nm)] [-J; sparse(nj,nj); [sparse(nc,na) Mu -EE']] [sparse(nm+na+nc,nc); EE; sparse(nc,nc)]];
      J              = [J sparse(nm,nc)];
      q              = [q; zeros(3*nc,1)];      
      ixc            = x0_index(end-nc+1:end);
      ix             = [x0_index; ixc+nc; ixc+2*nc; ixc+3*nc];
   end
end

% --- get current x0, solve, update x0
x0    = full_x0(ix);
nh    = size(H,1);
if nm == nh
   x                 = -H \ q;
elseif nh - nm == 1 
   x                 = -H \ q;
   if E.skin > 0
      x(end)            = E.skin*log(1+exp(x(end)/E.skin));
%       x(end)            = .5*(sqrt(4*E.skin^2+x(end).^2) + x(end));
   else
      x(end)            = max(x(end),0);
   end
else
   if E.solver == 1
      lb             = [-inf(nm,1); zeros(nh-nm,1)];
      ub             = inf(nh,1);
      x              = LCP(H,q,lb,ub,x0,0);
   else
      lb             = [-1e20*ones(nm,1); zeros(nh-nm,1)];
      ub             = 1e20*ones(nh,1);   
      x              = x0;
      [status,tt]    = lcppath(length(q), nnz(H), x, lb, ub, H, q);
   end
end
full_x0(ix) = x;

% % Some hackey code for drawing H's sparsity pattern
% sp  = findobj(gcf,'tag','sparsity');
% set(sp,'Cdata',ceil(imresize(double(full(logical(H))), [50 50])*64))
% % end hack
