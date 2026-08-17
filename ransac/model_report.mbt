///|
/// Human- and machine-readable summary for an estimated model.
pub(all) struct ModelReport {
  iterations : Int
  inliers : Int
  total : Int
  ratio : Double
  score : Double
  converged : Bool
} derive(Debug, Eq)

///|
pub fn make_model_report(
  iterations~ : Int,
  inliers~ : Int,
  total~ : Int,
  score~ : Double,
  converged~ : Bool,
) -> ModelReport {
  {
    iterations: iterations.max(0),
    inliers: inliers.max(0).min(total.max(0)),
    total: total.max(0),
    ratio: if total <= 0 {
      0.0
    } else {
      inliers.to_double() / total.to_double()
    },
    score,
    converged,
  }
}

///|
pub fn ModelReport::is_usable(
  report : ModelReport,
  minimum_ratio : Double,
  minimum_inliers : Int,
) -> Bool {
  report.converged &&
  report.inliers >= minimum_inliers &&
  report.ratio >= minimum_ratio
}

///|
pub fn ModelReport::confidence(report : ModelReport) -> Double {
  (report.ratio * (1.0 - 1.0 / (report.iterations + 1).to_double()))
  .max(0.0)
  .min(1.0)
}

///|
pub fn rank_model_reports(
  reports : ArrayView[ModelReport],
) -> Array[ModelReport] {
  let result = reports.to_owned()
  result.sort_by(fn(a, b) {
    if a.inliers != b.inliers {
      b.inliers - a.inliers
    } else if a.score > b.score {
      -1
    } else if a.score < b.score {
      1
    } else {
      0
    }
  })
  result
}

///|
pub fn best_model_report(reports : ArrayView[ModelReport]) -> ModelReport? {
  let ranked = rank_model_reports(reports)
  if ranked.length() == 0 {
    None
  } else {
    Some(ranked[0])
  }
}

///|
pub fn report_summary(reports : ArrayView[ModelReport]) -> (Int, Int, Double) {
  let mut usable = 0
  let mut total = 0
  let mut score = 0.0
  for report in reports {
    if report.converged {
      usable += 1
    }
    total += report.inliers
    score += report.score
  }
  (usable, total, score)
}
