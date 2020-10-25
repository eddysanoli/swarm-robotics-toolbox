clear E
% --- select model
E  = m_man;

% --- global parameters
E.skin            = 0;
E.stretch         = 1;
E.k_fric          = 0.3;
E.RK              = 0;
E.friction_model  = 1;
E.solver          = 1;
E.k_drag          = .1;
E.margin          = 1;
E.walls(:,3)      = E.walls(:,3)-1e-5;
E.k_grav          = [0 -9.8 0];

% --- initialize
E                 = initE(E);

% simulate
simulate(E);


