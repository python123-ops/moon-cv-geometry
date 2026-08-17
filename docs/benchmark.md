# Reproducible benchmark record

This record is for the August 2026 MoonBit Hackathon acceptance build. It uses
the checked-in examples and the real local MoonBit stable toolchain; it does not
present synthetic numbers as a camera or image-dataset benchmark.

## Environment

- Moon CLI: `0.1.20260807`
- Moonc: `0.10.7+bc794d341`
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

The acceptance run completed 49 tests with 49 passed and 0 failed on every
target. Measured local command wall times were 0.77 s for all-target check,
7.39 s for all-target tests, and 0.94 s for packaging. These are regression
indicators for the same working tree, not cross-machine speed claims.

The numerical acceptance thresholds are reproducible: exact pinhole projection
round trips stay below `1e-9`, distortion inversion below `1e-6`, exact
homography/epipolar residuals below `1e-5`, and injected-outlier RANSAC keeps at
least 80% inliers.
