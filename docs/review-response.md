# Review Response

This note answers the issues raised in the OSC2026 initial review email.

## 1. LICENSE Was Too Short

Fixed. The repository now contains the complete Apache License 2.0 text in
`LICENSE`, using the official Apache license text. Copyright and project notice
information are kept in `NOTICE`.

## 2. Authorship Needed Clarification

Fixed. The repository now includes `docs/authorship-and-provenance.md`, which
records the participant, repository identities, Mooncakes namespace correction,
and source provenance.

Summary:

- Participant: Zhang Jingkai
- GitHub contributor identity: `python123-ops`
- GitLink contributor identity: `python123`
- Current Mooncakes module at the first review response: `python123-ops/moon-cv-geometry@0.1.1`
- Source status: original MoonBit implementation, no copied third-party source

## 3. Why `曹显灏` May Have Appeared

The current GitHub and GitLink repositories do not contain `曹显灏` as a
contributor, author, committer, or source text match. The likely source of this
confusion is the old Mooncakes namespace `cxh04/moon-cv-geometry@0.1.0`, which
was published during release preparation before the module was corrected to the
current `python123-ops/moon-cv-geometry` namespace.

The submitted package should be reviewed under:

```text
python123-ops/moon-cv-geometry@0.1.1
```

## 4. Verification

The repository is expected to pass:

```bash
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
moon package
```

GitHub Actions runs the same checks on Ubuntu, macOS, and Windows.
