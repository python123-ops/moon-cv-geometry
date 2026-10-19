#!/usr/bin/env python3
"""Run strict checks, four-backend tests, checked examples, and package validation."""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, help='Optional path for full JSON results')
    args = parser.parse_args()
    moon = os.environ.get('MOON', 'moon')
    records = []
    interfaces = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in ROOT.rglob('pkg.generated.mbti')
                  if '_build' not in p.parts and '.mooncakes' not in p.parts}

    def run(arguments, output_check=None):
        completed = subprocess.run([moon] + arguments, cwd=ROOT, capture_output=True, timeout=300)
        stdout = completed.stdout.decode('utf-8', errors='replace')
        stderr = completed.stderr.decode('utf-8', errors='replace')
        passed = completed.returncode == 0
        if passed and output_check:
            passed = bool(output_check(stdout))
        records.append({'command': [moon] + arguments, 'exit_code': completed.returncode,
                        'passed': passed, 'stdout': stdout, 'stderr': stderr})
        print(('PASS ' if passed else 'FAIL ') + ' '.join(arguments), flush=True)
        if not passed:
            raise RuntimeError('Verification failed: ' + ' '.join(arguments))

    def numeric_output(label, expected, tolerance=1.0e-8):
        def matches(stdout):
            match = re.search(re.escape(label) + r'([^\r\n]+)', stdout)
            if not match:
                return False
            try:
                values = [float(value.strip()) for value in match.group(1).split(',')]
            except ValueError:
                return False
            return len(values) == len(expected) and all(
                math.isfinite(actual) and abs(actual - target) <= tolerance
                for actual, target in zip(values, expected))
        return matches

    success = False
    error = None
    interface_stable = None
    try:
        run(['version', '--all'])
        run(['fmt', '--check'])
        run(['check', '--target', 'all', '--deny-warn'])
        run(['test', '--target', 'all', '--deny-warn', '--enable-coverage'])
        run(['info'])
        current = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in ROOT.rglob('pkg.generated.mbti')
                   if '_build' not in p.parts and '.mooncakes' not in p.parts}
        interface_stable = current == interfaces
        if not interface_stable:
            raise RuntimeError('Generated interfaces drifted; review and save moon info output first')
        for target in ['wasm-gc', 'native']:
            for example, label, expected in [
                ('project_point', 'projected pixel: ', [445.0, 490.0]),
                ('undistort', 'recovered: ', [0.2, -0.1]),
                ('homography', 'mapped point: ', [10.5, 21.5]),
                ('fundamental_ransac', 'inliers: ', [8.0]),
                ('detection_bounds', 'target bbox xywh: ', [20.0, 30.0, 20.0, 20.0]),
            ]:
                run(['run', 'examples/' + example, '--target', target, '--deny-warn'],
                    numeric_output(label, expected))
        run(['package'])
        success = True
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as failure:
        error = str(failure)
        print(error, file=sys.stderr)
    report = {'platform': sys.platform, 'passed': success,
              'interface_regeneration_stable': interface_stable,
              'checks': records, 'error': error}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
