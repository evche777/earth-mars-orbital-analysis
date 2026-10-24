# Learning and Interview Guide

Use this page to understand and explain the analysis. You do not need to
memorise the MATLAB implementation.

## The project in one sentence

I calculated an ideal minimum-energy Earth-to-Mars transfer, estimated the
planetary departure and capture burns, and checked the analytic orbit with an
independent numerical propagation.

## Five ideas to understand

1. **Hohmann ellipse:** the minimum-energy transfer ellipse touches Earth's
   circular orbit at perihelion and Mars' circular orbit at aphelion.
2. **Transfer time:** half of the transfer ellipse's orbital period, obtained
   from Kepler's third law; here it is about 259 days.
3. **Phase angle:** Mars must start about 44.3 degrees ahead of Earth so that
   Mars and the spacecraft reach the intercept together.
4. **Hyperbolic-excess speed:** the heliocentric speed mismatch at each planet
   becomes the incoming or outgoing excess speed in the planet-centred model.
5. **Patched conics:** separate Sun-, Earth- and Mars-centred two-body models
   are joined to estimate the departure and capture burns.

## What the MATLAB does

- Defines published gravitational and planetary constants.
- Applies Kepler and vis-viva equations to the transfer ellipse.
- Calculates the Earth departure and Mars capture delta-v values.
- Integrates the Sun-centred equations of motion with `ode45`.
- Compares the numerical endpoint with the analytic Mars intercept.
- Checks conservation of orbital energy and angular momentum.
- Produces the four result plots and two summary files.

## Likely interview questions

**Why is this not a real mission design?**  It assumes circular, coplanar
planetary orbits and instantaneous burns. A real study would use dated
ephemerides, a Lambert solver, launch constraints and correction manoeuvres.

**Why propagate numerically after solving analytically?**  It provides an
independent validation: the integrated trajectory should reach the analytic
intercept and conserve energy and angular momentum.

**What does the timing plot mean?**  It holds the ideal transfer orbit fixed
and changes only the departure phase. It demonstrates how quickly the
intercept is lost away from the ideal geometry; it is not an optimiser.

**What would you add next?**  Use real Earth and Mars states for selected
dates, solve Lambert's problem, and compare the resulting delta-v across a
grid of departure and arrival dates.

## A short demonstration

1. Run `run_analysis`.
2. State the 259-day transfer time and 44.3-degree phase angle.
3. Show `trajectory_overview.png` and identify the transfer ellipse.
4. Show `delta_v_budget.png` and explain departure versus capture.
5. Finish with `numerical_conservation.png` as the validation evidence.
