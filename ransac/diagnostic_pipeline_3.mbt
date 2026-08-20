///|
/// Diagnostic time-series helpers for monitoring robust estimators in production.
pub fn diagnostic_series_mean(reports : ArrayView[DiagnosticReport]) -> Double {
  if reports.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for report in reports {
      total += report.rms
    }
    total / reports.length().to_double()
  }
}

///|
pub fn diagnostic_series_maximum(
  reports : ArrayView[DiagnosticReport],
) -> Double {
  let mut result = 0.0
  for report in reports {
    result = result.max(report.rms)
  }
  result
}

///|
pub fn diagnostic_series_minimum(
  reports : ArrayView[DiagnosticReport],
) -> Double {
  if reports.length() == 0 {
    0.0
  } else {
    let mut result = reports[0].rms
    for report in reports {
      result = result.min(report.rms)
    }
    result
  }
}

///|
pub fn diagnostic_series_improvement(
  reports : ArrayView[DiagnosticReport],
) -> Double {
  if reports.length() < 2 {
    0.0
  } else {
    let first = reports[0].rms
    let last = reports[reports.length() - 1].rms
    if first <= 0.0 {
      0.0
    } else {
      (first - last) / first
    }
  }
}

///|
pub fn diagnostic_series_inlier_mean(
  reports : ArrayView[DiagnosticReport],
) -> Double {
  if reports.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for report in reports {
      total += report.inlier_ratio
    }
    total / reports.length().to_double()
  }
}

///|
pub fn diagnostic_series_stable(
  reports : ArrayView[DiagnosticReport],
  tolerance : Double,
) -> Bool {
  if reports.length() < 2 {
    true
  } else {
    (diagnostic_series_maximum(reports) - diagnostic_series_minimum(reports)).abs() <=
    tolerance.max(0.0)
  }
}

///|
pub fn diagnostic_series_pass_count(
  reports : ArrayView[DiagnosticReport],
  minimum_inliers : Int,
  maximum_rms : Double,
) -> Int {
  let mut result = 0
  for report in reports {
    if diagnostic_report_passes(report, minimum_inliers, maximum_rms) {
      result += 1
    }
  }
  result
}

///|
pub fn diagnostic_series_pass_ratio(
  reports : ArrayView[DiagnosticReport],
  minimum_inliers : Int,
  maximum_rms : Double,
) -> Double {
  if reports.length() == 0 {
    0.0
  } else {
    diagnostic_series_pass_count(reports, minimum_inliers, maximum_rms).to_double() /
    reports.length().to_double()
  }
}

///|
pub fn diagnostic_series_buckets(
  reports : ArrayView[DiagnosticReport],
) -> Array[Int] {
  let result = [0, 0, 0]
  for report in reports {
    let bucket = diagnostic_quality_bucket(report).min(2).max(0)
    result[bucket] += 1
  }
  result
}

///|
pub fn diagnostic_series_last(
  reports : ArrayView[DiagnosticReport],
) -> DiagnosticReport? {
  if reports.length() == 0 {
    None
  } else {
    Some(reports[reports.length() - 1])
  }
}

///|
pub fn diagnostic_series_best(
  reports : ArrayView[DiagnosticReport],
) -> DiagnosticReport? {
  if reports.length() == 0 {
    None
  } else {
    let mut result = reports[0]
    for report in reports[1:] {
      if report.rms < result.rms {
        result = report
      }
    }
    Some(result)
  }
}

///|
pub fn diagnostic_series_take(
  reports : ArrayView[DiagnosticReport],
  count : Int,
) -> Array[DiagnosticReport] {
  let result : Array[DiagnosticReport] = []
  for i in 0..<count.max(0).min(reports.length()) {
    result.push(reports[i])
  }
  result
}

///|
pub fn diagnostic_series_drop(
  reports : ArrayView[DiagnosticReport],
  count : Int,
) -> Array[DiagnosticReport] {
  let result : Array[DiagnosticReport] = []
  for i in count.max(0).min(reports.length())..<reports.length() {
    result.push(reports[i])
  }
  result
}

///|
pub fn diagnostic_series_window(
  reports : ArrayView[DiagnosticReport],
  start : Int,
  width : Int,
) -> Array[DiagnosticReport] {
  diagnostic_series_take(diagnostic_series_drop(reports, start), width)
}

///|
pub fn diagnostic_series_append(
  target : Array[DiagnosticReport],
  reports : ArrayView[DiagnosticReport],
) -> Unit {
  for report in reports {
    target.push(report)
  }
}

///|
pub fn diagnostic_series_merge(
  left : ArrayView[DiagnosticReport],
  right : ArrayView[DiagnosticReport],
) -> Array[DiagnosticReport] {
  let result = left.to_owned()
  diagnostic_series_append(result, right)
  result
}

///|
pub fn diagnostic_series_scale(
  reports : ArrayView[DiagnosticReport],
  scale : Double,
) -> Array[DiagnosticReport] {
  let result : Array[DiagnosticReport] = []
  for report in reports {
    result.push(diagnostic_report_scale(report, scale))
  }
  result
}

///|
pub fn diagnostic_series_labels(
  reports : ArrayView[DiagnosticReport],
) -> Array[String] {
  let result : Array[String] = []
  for report in reports {
    result.push(report.label)
  }
  result
}

///|
pub fn diagnostic_series_summary(
  reports : ArrayView[DiagnosticReport],
) -> String {
  diagnostic_series_mean(reports).to_string() +
  "," +
  diagnostic_series_maximum(reports).to_string() +
  "," +
  diagnostic_series_inlier_mean(reports).to_string()
}

///|
pub fn diagnostic_series_quality(
  reports : ArrayView[DiagnosticReport],
  minimum_inliers : Int,
  maximum_rms : Double,
) -> Double {
  diagnostic_series_pass_ratio(reports, minimum_inliers, maximum_rms) *
  (1.0 / (1.0 + diagnostic_series_mean(reports)))
}
