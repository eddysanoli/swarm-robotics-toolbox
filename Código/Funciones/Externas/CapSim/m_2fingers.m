function E = m_hand

E.mechanisms  = [1 1 1 1 2]';
E.anchors     = [0 0 -1;nan nan nan];
E.radii       = ones(5,1)*[.5 .3];
E.masses      = pi*sum(E.radii.^2,2);
E.joints      = [1 2; 2 4; 1 3]; % random tree
E.j_locs      = [1 1 -1; -1 -1 -1]';
E.j_constr    = [];
E.a_constr    = [];
E.a_lims      = zeros(0,2);
E.draw_order  = 1:5;
E.collidable  = false(5);
E.collidable(3,5) = true;
E.collidable(4,5) = true;
E.collidable  = E.collidable | E.collidable'; 
E.walls       = [0 1 -5; 1 0 -5; -1 0 -5; 0 -1 -5];