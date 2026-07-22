# Numerical Conventions

- Coordinates use `Double`.
- Camera coordinates assume positive `z` is in front of the camera.
- Pixel coordinates follow the common `(x, y)` image convention with origin at
  the top-left unless the caller defines a different convention externally.
- Thresholds are explicit in RANSAC config and tests use fixed seeds.
- Small fixed-size matrices are implemented locally to avoid depending on a
  broad linear algebra package for the base camera geometry layer.
