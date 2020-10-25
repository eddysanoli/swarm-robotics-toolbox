CapSim
======

CapSim is an open-source planar physics simulator designed for academic purposes.
The main features are:

*  Simple yet full featured, %100 Matalab code for readability 
   and modifiability, perfect for research.

*  Planar capsules (a capsule is a segment with a radius) can be
   connected in arbitrary topologies, free floating or anchored

*  All computation are done in a minimal coordinate system, 
   i.e. angles and centers-of-mass, no "constraint stabillization"

*  Computation of centripetal and coriolis Jacobians allows us to use 
   semi-implicit Euler integration [1], which is just as cheap 
   as Euler, yet considerably more accurate.

*  Collision detection for both capsule-wall and capsule-capsule collisions

*  Full support for contact and friction impulses using either the
   classic model of [2], or the convexified model of [3]

*  Support for several LCP solvers, including the PATH solver [4],
   a solver based on the semi-smooth algorithm of Fisher [5].


Instructions
============

1) Run test_sim.m to play with an interactive simulation.

2) Read tutorial.m to learn how to build your own models.

3) Read the underlying code to learn how the physics simulation works.

4) Modify the code, improve it, give back to the community.



References
==========
[1] Potra Et Al "A linearly implicit trapezoidal method for integrating 
stiff multibody dynamics with contact, joints, and friction"
Int. J. Numer. Meth. Eng. 2000; 00:1–6

[2] M. Anitescu and F. A. Potra, “Formulating dynamic Multi-Rigid-
Body contact problems with friction as solvable linear complementarity
problems,” Nonlinear Dynamics, vol. 14, no. 3, pp. 231–247, Nov. 1997.

[3] M. Anitescu, “Optimization-based simulation of nonsmooth rigid multibody
dynamics,” Mathematical Programming, vol. 105, no. 1, pp. 113–
143, 2006.

[4] Ferris, M.C. and Munson, T.S., "Complementarity problems in GAMS and 
the PATH solver", Journal of Economic Dynamics and Control, vol. 24, no. 2,
pp. 165-188, 2000.

[5] A. Fisher "A Newton-Type Method for Positive-Semidefinite Linear 
Complementarity Problems" JOURNAL OF OPTIMIZATION THEORY AND APPLICATIONS: 
Vol. 86, No. 3, pp. 585-608, SEPTEMBER 1995