# Earth--Mars Transfer and Mars Orbit-Insertion Study

## 1. Aim

This study estimates a minimum-energy Earth-to-Mars trajectory and the
impulsive velocity changes required to leave a 300 km circular low-Earth
orbit and enter a 300 km circular orbit around Mars.

The purpose is to demonstrate orbital-mechanics reasoning, numerical
propagation, validation and interpretation. It is not a flight-ready mission
design.

## 2. Assumptions

- Earth and Mars follow circular, coplanar heliocentric orbits.
- The spacecraft follows a Sun-centred two-body trajectory between planetary
  spheres of influence.
- Departure and capture are instantaneous burns.
- The planetary-orbit calculations use a patched-conic approximation.
- Atmospheric drag, planetary eccentricity, inclination, third-body effects,
  launch-site geometry, finite burns and mid-course corrections are omitted.

These assumptions isolate the main astrodynamics and make every result
traceable to a small set of equations.

## 3. Analytic transfer model

For Earth orbital radius `r_E` and Mars orbital radius `r_M`, the Hohmann
transfer semi-major axis is

```text
a_t = (r_E + r_M) / 2.
```

The Sun-centred transfer time is half the period of that ellipse:

```text
t_H = pi * sqrt(a_t^3 / mu_Sun).
```

The heliocentric transfer speeds at Earth and Mars follow from the vis-viva
equation:

```text
v = sqrt(mu_Sun * (2/r - 1/a_t)).
```

Subtracting the corresponding planetary circular speed gives the departure
and arrival hyperbolic-excess speeds. The ideal initial phase angle places Mars
ahead of Earth by

```text
phi = pi - n_M * t_H,
```

where `n_M` is Mars' mean motion.

## 4. Patched-conic delta-v model

At a parking-orbit radius `r_p`, the hyperbolic periapsis speed is

```text
v_p = sqrt(v_infinity^2 + 2*mu_planet/r_p).
```

The impulsive burn is the difference between that speed and the local circular
speed. The same calculation is applied at Earth departure and Mars arrival.

## 5. Numerical propagation

The transfer state is independently propagated with MATLAB's `ode45` using
the planar two-body equations

```text
r_ddot = -mu_Sun * r / |r|^3.
```

The numerical final state is compared with Mars' analytically propagated
position. Specific orbital energy and angular momentum are monitored across
the integration as conservation checks.

## 6. Principal results

| Quantity | Result |
|---|---:|
| Transfer semi-major axis | 1.261840 AU |
| Transfer time | 258.865759 days |
| Required Mars phase angle | 44.344171 degrees |
| Earth--Mars synodic period | 779.949446 days |
| Earth departure hyperbolic excess | 2.944689 km/s |
| Mars arrival hyperbolic excess | 2.648895 km/s |
| 300 km LEO departure burn | 3.589978 km/s |
| 300 km Mars circular capture burn | 2.090639 km/s |
| Total idealised impulsive delta-v | 5.680618 km/s |
| Numerical arrival miss | 0.000012 km |
| Maximum relative energy error | 2.85 x 10^-14 |
| Maximum relative angular-momentum error | 7.79 x 10^-15 |

The transfer duration and phase angle are consistent with the familiar
minimum-energy Earth-to-Mars geometry. The roughly 780-day synodic period
explains why favourable opportunities repeat approximately every 26 months.
The small numerical intercept and conservation errors confirm that the
independent propagation reproduces the analytic two-body solution to the
chosen integration tolerance.

## 7. Timing sensitivity

The timing study changes the relative Earth--Mars phase at departure while
holding the ideal transfer orbit fixed. It therefore measures how quickly a
perfect Hohmann intercept is lost when departure is moved away from the ideal
window. It is a sensitivity study, not a full launch-window optimiser.

## 8. Interpretation

The model shows that a simple analytic calculation can establish the main
mission geometry, while numerical propagation provides a separate check. The
patched-conic burns connect the heliocentric trajectory to operationally
meaningful parking and capture orbits.

The largest simplification is the use of circular, coplanar planetary orbits.
A higher-fidelity extension would replace them with dated JPL ephemerides and
solve a Lambert boundary-value problem for a chosen departure and arrival
date.

## 9. References

- [JPL Solar System Dynamics: Astrodynamic Parameters](https://ssd.jpl.nasa.gov/astro_par.html)
- [NASA/JPL: Calculating Earth--Mars Launch Windows](https://www.jpl.nasa.gov/edu/resources/lesson-plan/lets-go-to-mars-calculating-launch-windows/)
- [NASA Basics of Space Flight: Trajectories](https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/)
- H. D. Curtis, *Orbital Mechanics for Engineering Students*.

