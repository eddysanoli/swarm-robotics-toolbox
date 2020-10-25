function E = m_man()

E.mechanisms   = ones(12,1);
E.anchors      = [nan nan];
E.radii        = .1*[ 5     2;...%1  torso
                      3     1;...%2  arm1
                      3.3  .7;...%3  forearm1
                      3     1;...%4  arm2
                      3.3  .7;...%5  forearm2
                      4.5 1.5;...%6  thigh1
                      4     1;...%7  shin1
                      2.3  .7;...%8  foot1
                      4.5 1.5;...%9  thigh2
                      4     1;...%10 shin2
                      2.3  .7;...%11 foot2
                      1   2.5];  %12 head
E.masses      = pi*E.radii(:,2).^2 + 4*E.radii(:,1).*E.radii(:,2);
E.joints      = [ 1    2;  2    3;  1    4;  4    5;  1   6;  6  7; 7   8;  1   9;  9 10; 10  11;  1  12];
E.j_locs      = [.7   -1;  1   -1; .7   -1;  1   -1;-.9 -.9;  1 -1; 1 -.5;-.9 -.9;  1 -1; 1  -.5;  1 -1.3];
E.a_lims      = [0   4.5; -2.4  0;  0  4.5; -2.4  0;  1 3.5; .4  2;-2 -.7;  1 3.5; 0.4 2; -2 -.7;-0.5 0.5];
E.a_lims      = wrap(E.a_lims);
E.j_constr    = (1:size(E.joints,1))';
E.a_constr    = [];
E.draw_order  = [2 3 6 7 8 1 12 9 10 11 4 5];
n           = 12;
E.collidable  = false(n);
E.walls       = [0 1 -5; 1 0 -5; -1 0 -5; 0 -1 -5];

%add some pebbles
np = 5;
E.mechanisms  = [E.mechanisms; [2:np+1]'];
E.anchors     = [E.anchors; nan(np,2)];
E.radii       = [E.radii; sort((rand(np,2)+0.3)/sqrt(np),2,'descend')];
E.masses      = pi*E.radii(:,2).^2 + 4*E.radii(:,1).*E.radii(:,2);
E.draw_order  = [E.draw_order (n+1:n+np)];
n           = n+np;
E.collidable  = logical(triu(ones(n),1));
E.collidable(:,1:12) = false;