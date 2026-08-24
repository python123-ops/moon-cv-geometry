# Contributing

This repository is maintained as a single-author OSC2026 project. Proposed
changes should begin as issues or design discussions so that API compatibility
and numerical behavior can be reviewed before code is contributed.

Quality expectations:

- Keep APIs focused on camera and multi-view geometry.
- Add tests with every behavior change.
- Run `moon check --target all`, `moon test --target all`, `moon fmt`, and
  `moon info` before proposing changes.
- Document any external algorithm reference and do not copy incompatible code.
