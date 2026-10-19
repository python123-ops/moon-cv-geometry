# Contributing

This repository is maintained as a single-author OSC2026 project. Proposed
changes should begin as issues or design discussions so that API compatibility
and numerical behavior can be reviewed before code is contributed.

Quality expectations:

- Keep APIs focused on camera and multi-view geometry.
- Add tests with every behavior change.
- Run `moon check --target all --deny-warn`, `moon test --target all --deny-warn`,
  `moon fmt`, and `moon info` before proposing changes; do not suppress warnings.
- Use `python scripts/verify.py --report _build/verification.json` for the full
  gate, including numerical example checks and packaging. Python 3.8+, Moonc
  0.10.14+, Node.js, and a native C compiler are required.
- Document any external algorithm reference and do not copy incompatible code.
