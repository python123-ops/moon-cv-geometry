///|
/// Model-selection and audit helpers for production consensus pipelines.
pub(all) struct ModelSelectionSummary {
  candidates : Int
  usable : Int
  best_index : Int
  best_score : Double
  mean_ratio : Double
  mean_iterations : Double
} derive(Debug, Eq)

///|
pub fn model_report_score(
  report : ModelReport,
  ratio_weight : Double,
  iteration_weight : Double,
) -> Double {
  report.ratio * ratio_weight.max(0.0) +
  report.score -
  report.iterations.to_double() * iteration_weight.max(0.0)
}

///|
pub fn model_report_rank(
  reports : ArrayView[ModelReport],
  minimum_ratio : Double,
  minimum_inliers : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<reports.length() {
    if reports[i].is_usable(minimum_ratio, minimum_inliers) {
      result.push(i)
    }
  }
  result
}

///|
pub fn model_report_best_index(
  reports : ArrayView[ModelReport],
  minimum_ratio : Double,
  minimum_inliers : Int,
) -> Int {
  let mut best = -1
  let mut best_score = -1.0e300
  for i in 0..<reports.length() {
    if reports[i].is_usable(minimum_ratio, minimum_inliers) {
      let score = model_report_score(reports[i], 1.0, 0.000001)
      if best < 0 || score > best_score {
        best = i
        best_score = score
      }
    }
  }
  best
}

///|
pub fn model_report_best(
  reports : ArrayView[ModelReport],
  minimum_ratio : Double,
  minimum_inliers : Int,
) -> ModelReport? {
  let index = model_report_best_index(reports, minimum_ratio, minimum_inliers)
  if index < 0 {
    None
  } else {
    Some(reports[index])
  }
}

///|
pub fn model_selection_summary(
  reports : ArrayView[ModelReport],
  minimum_ratio : Double,
  minimum_inliers : Int,
) -> ModelSelectionSummary {
  let best = model_report_best_index(reports, minimum_ratio, minimum_inliers)
  let mut usable = 0
  let mut ratio = 0.0
  let mut iterations = 0.0
  for report in reports {
    if report.is_usable(minimum_ratio, minimum_inliers) {
      usable += 1
    }
    ratio += report.ratio
    iterations += report.iterations.to_double()
  }
  {
    candidates: reports.length(),
    usable,
    best_index: best,
    best_score: if best < 0 {
      0.0
    } else {
      model_report_score(reports[best], 1.0, 0.000001)
    },
    mean_ratio: if reports.length() == 0 {
      0.0
    } else {
      ratio / reports.length().to_double()
    },
    mean_iterations: if reports.length() == 0 {
      0.0
    } else {
      iterations / reports.length().to_double()
    },
  }
}

///|
pub fn model_report_filter_converged(
  reports : ArrayView[ModelReport],
) -> Array[ModelReport] {
  let result : Array[ModelReport] = []
  for report in reports {
    if report.converged {
      result.push(report)
    }
  }
  result
}

///|
pub fn model_report_filter_ratio(
  reports : ArrayView[ModelReport],
  minimum_ratio : Double,
) -> Array[ModelReport] {
  let result : Array[ModelReport] = []
  for report in reports {
    if report.ratio >= minimum_ratio {
      result.push(report)
    }
  }
  result
}

///|
pub fn model_report_filter_inliers(
  reports : ArrayView[ModelReport],
  minimum_inliers : Int,
) -> Array[ModelReport] {
  let result : Array[ModelReport] = []
  for report in reports {
    if report.inliers >= minimum_inliers {
      result.push(report)
    }
  }
  result
}

///|
pub fn model_report_sort_by_score(
  reports : ArrayView[ModelReport],
) -> Array[ModelReport] {
  let result = reports.to_owned()
  result.sort_by(fn(left, right) {
    model_report_score(right, 1.0, 0.000001).compare(
      model_report_score(left, 1.0, 0.000001),
    )
  })
  result
}

///|
pub fn model_report_sort_by_ratio(
  reports : ArrayView[ModelReport],
) -> Array[ModelReport] {
  let result = reports.to_owned()
  result.sort_by(fn(left, right) { right.ratio.compare(left.ratio) })
  result
}

///|
pub fn model_report_consensus_ratio(reports : ArrayView[ModelReport]) -> Double {
  if reports.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for report in reports {
    total += report.ratio
  }
  total / reports.length().to_double()
}

///|
pub fn model_report_consensus_spread(
  reports : ArrayView[ModelReport],
) -> Double {
  if reports.length() == 0 {
    return 0.0
  }
  let mean = model_report_consensus_ratio(reports)
  let mut total = 0.0
  for report in reports {
    let delta = report.ratio - mean
    total += delta * delta
  }
  (total / reports.length().to_double()).sqrt()
}

///|
pub fn model_report_stability(
  reports : ArrayView[ModelReport],
  maximum_spread : Double,
) -> Double {
  if maximum_spread <= 0.0 {
    return 0.0
  }
  (1.0 - model_report_consensus_spread(reports) / maximum_spread)
  .max(0.0)
  .min(1.0)
}

///|
pub fn model_report_merge(
  left : ModelReport,
  right : ModelReport,
) -> ModelReport {
  make_model_report(
    iterations=left.iterations.max(right.iterations),
    inliers=left.inliers.max(right.inliers),
    total=left.total.max(right.total),
    score=left.score.max(right.score),
    converged=left.converged || right.converged,
  )
}

///|
pub fn model_report_merge_all(reports : ArrayView[ModelReport]) -> ModelReport {
  if reports.length() == 0 {
    return make_model_report(
      iterations=0,
      inliers=0,
      total=0,
      score=0.0,
      converged=false,
    )
  }
  let mut result = reports[0]
  for report in reports[1:] {
    result = model_report_merge(result, report)
  }
  result
}

///|
pub fn model_report_reliability(
  report : ModelReport,
  maximum_iterations : Int,
) -> Double {
  let convergence = if report.converged { 1.0 } else { 0.0 }
  let iteration = if maximum_iterations <= 0 {
    0.0
  } else {
    (1.0 - report.iterations.to_double() / maximum_iterations.to_double()).max(
      0.0,
    )
  }
  convergence * report.ratio * (0.5 + 0.5 * iteration)
}

///|
pub fn model_report_is_degenerate(report : ModelReport) -> Bool {
  report.total <= 0 ||
  report.inliers <= 0 ||
  report.ratio <= 0.0 ||
  report.score.is_nan()
}

///|
pub fn model_report_quality_bucket(report : ModelReport) -> Int {
  if model_report_is_degenerate(report) {
    0
  } else if report.ratio >= 0.8 && report.converged {
    3
  } else if report.ratio >= 0.5 {
    2
  } else {
    1
  }
}

///|
pub fn model_report_bucket_counts(
  reports : ArrayView[ModelReport],
) -> Array[Int] {
  let result = [0, 0, 0, 0]
  for report in reports {
    let bucket = model_report_quality_bucket(report)
    result[bucket] += 1
  }
  result
}

///|
pub fn model_report_to_csv(report : ModelReport) -> String {
  report.iterations.to_string() +
  "," +
  report.inliers.to_string() +
  "," +
  report.total.to_string() +
  "," +
  report.ratio.to_string() +
  "," +
  report.score.to_string() +
  "," +
  report.converged.to_string()
}

///|
pub fn model_reports_to_csv(reports : ArrayView[ModelReport]) -> String {
  let mut result = "iterations,inliers,total,ratio,score,converged"
  for report in reports {
    result += "\n" + model_report_to_csv(report)
  }
  result
}

///|
pub fn model_report_expected_success(
  report : ModelReport,
  confidence : Double,
) -> Double {
  let probability = report.ratio.max(0.0).min(1.0)
  let mut miss = 1.0
  for _ in 0..<confidence.max(0.0).to_int() {
    miss *= 1.0 - probability
  }
  1.0 - miss
}

///|
pub fn model_report_budget(
  report : ModelReport,
  maximum_iterations : Int,
) -> Int {
  (maximum_iterations.max(0) - report.iterations.max(0)).max(0)
}
