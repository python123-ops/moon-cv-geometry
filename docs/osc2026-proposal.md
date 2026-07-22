# OSC2026 Proposal Draft

Project: moon-cv-geometry

Chinese name: moonbit视觉几何基石

Goal: provide a reusable MoonBit foundation for camera and multi-view geometry,
including points, vectors, small matrices, camera intrinsics/extrinsics,
distortion, projection, homography, epipolar constraints, and deterministic
RANSAC estimators.

Ecosystem value: MoonBit currently has useful math, rendering, GIS, and image
processing packages, but a focused camera-geometry layer is still missing. This
library avoids overlap with those packages and can serve calibration, AR, SLAM
experiments, panorama stitching, and robotics demos.

Deliverables: public GitHub and GitLink repositories, Apache-2.0 license,
Mooncakes release, runnable examples, tests, README, algorithm notes, and a
clear roadmap.

Validation: `moon check --target all`, `moon test --target all`, `moon fmt`,
and `moon info`.
