function E = m_pebbles(n)

E.mechanisms  = 1:n;
E.anchors     = nan(n,3);
E.radii       = (1*rand(n,2)+ones(n,1)*[2 .1])/sqrt(n);
E.masses      = pi*E.radii(:,2).^2 + 4*E.radii(:,1).*E.radii(:,2);
E.joints      = zeros(0,2);
E.j_locs      = zeros(0,2);
E.j_constr    = [];
E.a_constr    = [];
E.a_lims      = zeros(0,2);
E.draw_order  = 1:n;
E.collidable  = true(n);
E.walls       = [0 1 -5; 1 0 -5; -1 0 -5; 0 -1 -5];