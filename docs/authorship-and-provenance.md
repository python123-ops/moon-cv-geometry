# Authorship And Provenance

This document records the authorship, repository identities, and source
provenance for the OSC2026 submission `moon-cv-geometry`.

## Participant

- Participant name: Zhang Jingkai
- Project name: moonbit视觉几何基石
- Package name: `moon-cv-geometry`
- Current Mooncakes module: `python123-ops/moon-cv-geometry@0.1.1`

## Repository Identities

The project is maintained as a single-author OSC2026 entry. The two hosting
platforms use different real accounts:

- GitHub repository: `https://github.com/python123-ops/moon-cv-geometry`
- GitHub commit author: `python123-ops <python123-ops@users.noreply.github.com>`
- GitLink repository: `https://gitlink.org.cn/python123/moon-cv-geometry`
- GitLink commit author: `python123 <15564209090@163.com>`

Both repositories intentionally avoid synthetic or extra contributor identities.

## About The `cxh04` Mooncakes Namespace

The current submitted package is `python123-ops/moon-cv-geometry`. During release
preparation, version `0.1.0` was mistakenly published once under
`cxh04/moon-cv-geometry` before the package namespace was corrected. That old
Mooncakes namespace is not the competition submission namespace.

The corrected package was published under `python123-ops/moon-cv-geometry`, and
the current release line is `0.1.1`. Repository metadata, import paths,
documentation, and package manifests now point to `python123-ops/moon-cv-geometry`.

## Source Provenance

The MoonBit implementation in this repository is original project code. It uses
standard public mathematical formulas from camera geometry and projective
geometry, such as pinhole projection, Brown-Conrady distortion, homogeneous
coordinates, epipolar residuals, and RANSAC sampling. No third-party source code
has been copied into the repository.

The project deliberately avoids vendored code. It also avoids overlapping with
general-purpose MoonBit linear algebra, GIS geometry, rendering geometry, image
filtering, feature extraction, and deep-learning projects.

## Audit Commands

The following commands can be used to verify contributor and source identity:

```bash
git rev-list --count HEAD
git shortlog -sne HEAD
git log --all --format='%H %an <%ae> %cn <%ce>'
rg -n "曹显灏|cxh04" . -g '!_build' -g '!.git'
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
moon package
```

For GitLink, clone `https://gitlink.org.cn/python123/moon-cv-geometry.git` and
run the same `git rev-list`, `git shortlog`, and search commands.
