# falsify (vendored subset)

This directory holds the small part of the falsify flight-evaluation framework that the gate experiments depend
on, copied unchanged except for trimmed package `__init__` files, so that the judge used for every sim number in
the paper ships with the code. The full framework (simulation, recovery planning and the synthetic-data exporter)
is not included.

- `src/falsify/safety/posthoc.py` provides `check_directional_transit`, the judge `gate/gate_success.py` calls,
  with the 2026-09-25 fix that labels the transit direction by the measured aperture normal. `records.py`,
  `sim/dynamics_state.py` and `geometry/` are what it imports.
- `configs/scenes/*.yaml` give each scene's frames, gate placement and splat alignment, and
  `configs/safety/*.yaml` give the gate apertures (re-measured 2026-09-25) that the transit and clearance
  judges read.
- `configs/embodiments/assets/wrist_overlay_pinhole_rgb.png` is the airframe strut drawn over the downward
  camera view, matching what the onboard camera sees.
- `tests/test_directional_transit_normal.py` checks the direction labelling
  (`PYTHONPATH=third_party/falsify/src python -m pytest third_party/falsify/tests`).
