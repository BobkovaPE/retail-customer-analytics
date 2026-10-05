"""Optional Monte Carlo check; simulated draws are not campaign outcomes."""
from pathlib import Path
from statistics import NormalDist
import json

import numpy as np


def main():
    root = Path(__file__).resolve().parents[1]
    summary = json.loads((root / 'reports/stage5_summary.json').read_text())
    p0 = summary['historical_repeat_pct'] / 100
    n = summary['required_n_per_group_for_5pp']
    repetitions, seed = 200000, 20261005
    rng = np.random.default_rng(seed)
    rates = {}
    for uplift in [0.0, 0.05]:
        control = rng.binomial(n, p0, repetitions)
        treatment = rng.binomial(n, p0 + uplift, repetitions)
        pooled = (control + treatment) / (2*n)
        z = (treatment-control) / n / np.sqrt(pooled*(1-pooled)*2/n)
        rates[str(uplift)] = float(np.mean(np.abs(z) > NormalDist().inv_cdf(.975)))
    assert abs(rates['0.0'] - .05) < .004
    assert abs(rates['0.05'] - .80) < .015
    result = {
        'seed': seed, 'repetitions_per_scenario': repetitions, 'n_per_group': n,
        'baseline': p0, 'null_rejection_rate': rates['0.0'], 'power_at_5pp': rates['0.05'],
        'note': 'Monte Carlo verification of planning approximation; not campaign outcomes.',
    }
    (root / 'reports/power_simulation_check.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
