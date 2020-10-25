% Tutorial
% ========
% 
% In CapSim, all the static information about the model is contained in the
% structure E. Let's begin by making one now. 
clear E
% First we must define how many mechanisms and capsules we will have. 
% A "mechanism" is a group of capsules that are connected by joints.
% the i-th entry of E.mechanisms is the mechanism of the i-th capsule
E.mechanisms = [1 1 2 2 2]';
% We will have two mechanism in our model, the first composed of two 
% capsules, the second of three. Mechanisms can be either free-floating
% or anchored to the wall.

% the i-th row of E.anchors defines the anchor of the i-th mechanism
% as [x y l] where x and y are the position of the anchor and l is the
% location of the anchor on the major axis of the first capsule of the 
% i-th mechanism, in units of the segment length. off axis anchors are
% not yet supported. nans indicate free floating mechanism
E.anchors = [0 .5 0; nan nan nan];
% The first mechanism will be anchored to the wall at [0 .5], with the
% anchor at the center of the capsule. the second will be free floating. 

% E.a_constr specifies which anchors (if any) have joint limits
E.a_constr  = [];

% E.radii defines the shape of the capsules. A capsule is the set of points
% at a certain distance from a segment. the first column is the half
% length of the segment, while the second column is the radius around the 
% segment
E.radii = [1 1 1 1 1]'*[.7 .2];

% E.masses, pretty obvious, right?
E.masses = prod(E.radii,2);

% E.joints specifies which capsules are connected. Make sure this is not
% incompatible with E.mechanisms
E.joints = [1 2; 3 4; 4 5];

% E.j_locs specifies where is the joint on the major axes of the capsules,
% in half-segment units.
E.j_locs = [-1 1;-1 1;-1 1];
% our joints will all be at the ends of segments

E.j_constr  = [2 3]'; % Which joints have angle limits ?
E.a_lims    = [-pi/4 pi/4; -pi/4 pi/4]; % What are the angle limits

% let's add some walls. a row [a b c] in E.walls means that a*x+b*y > c, so
E.walls       = [0 1 -5; 1 0 -5; -1 0 -5; 0 -1 -5];
% means a box of 4 walls around [-5,5]^2

% finally let's allow the capsules from the two different mechanisms to 
% collide:
E.collidable            = false(5,5);
E.collidable(1,[3 4 5]) = true;
E.collidable(2,[3 4 5]) = true;

E.draw_order            = 1:5; 
% this is just the order in which to draw the capsules, useful for correct
% occlusions

% initialize the E structure
E = initE(E);

% Simulate !
simulate(E);

% hit ESC to stop the simulation.