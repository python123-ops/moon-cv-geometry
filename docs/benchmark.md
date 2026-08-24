# Reproducible benchmark record

This record describes the reproducible validation of the August 2026 MoonBit
Hackathon geometry library. It uses checked-in examples and deterministic
geometric data; it does not present synthetic numbers as a camera or image
dataset benchmark.

## Environment

- Moon CLI: `0.1.20260819`
- Moonc: `0.10.9+6e6c44045`
- Targets: wasm, wasm-gc, js and native
- Dataset: deterministic geometric correspondences in the checked-in package
  tests and examples

## Reproduction

```powershell
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn --enable-coverage
moon coverage report -f summary
moon coverage analyze
moon info
moon package
```

The current validation run completed 115 tests with 115 passed and 0 failed on
every target. The source tree contains approximately 20,000 MoonBit lines
across the reusable implementation packages, tests, and examples. Coverage is
reported as a diagnostic artifact by CI: the latest run covered 3,275 of 7,488
instrumented lines. Coverage is not used as a substitute for behavior-focused
tests.

Measured local command wall times are regression indicators for the same
working tree, not cross-machine speed claims. Re-run the commands below on the
target environment to refresh timing data.

The numerical quality thresholds are reproducible: exact pinhole projection
round trips stay below `1e-9`, distortion inversion below `1e-6`, exact
homography/epipolar residuals below `1e-5`, and injected-outlier RANSAC keeps at
least 80% inliers.
