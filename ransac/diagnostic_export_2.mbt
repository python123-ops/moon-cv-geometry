///|
/// Stable comma-separated diagnostic row for CI and benchmark artifacts.
pub fn diagnostic_csv_row(report : DiagnosticReport) -> String {
  report.total.to_string() +
  "," +
  report.inliers.to_string() +
  "," +
  report.inlier_ratio.to_string() +
  "," +
  report.mean_inlier.to_string() +
  "," +
  report.rms.to_string() +
  "," +
  report.maximum.to_string() +
  "," +
  report.label
}

///|
pub fn diagnostic_csv_header() -> String {
  "total,inliers,inlier_ratio,mean_inlier,rms,maximum,label"
}

///|
pub fn diagnostic_quality_bucket(report : DiagnosticReport) -> Int {
  if report.label == "good" {
    2
  } else if report.label == "review" {
    1
  } else {
    0
  }
}

///|
pub fn diagnostic_quality_name(bucket : Int) -> String {
  if bucket >= 2 {
    "good"
  } else if bucket == 1 {
    "review"
  } else {
    "poor"
  }
}

///|
pub fn diagnostic_report_rows(
  reports : ArrayView[DiagnosticReport],
) -> Array[String] {
  let result : Array[String] = []
  for report in reports {
    result.push(diagnostic_csv_row(report))
  }
  result
}

///|
pub fn diagnostic_csv_document(reports : ArrayView[DiagnosticReport]) -> String {
  let lines : Array[String] = [diagnostic_csv_header()]
  for row in diagnostic_report_rows(reports) {
    lines.push(row)
  }
  let mut result = ""
  for i in 0..<lines.length() {
    if i > 0 {
      result += "\n"
    }
    result += lines[i]
  }
  result
}

///|
pub fn diagnostic_json_like(report : DiagnosticReport) -> String {
  "{\"total\":" +
  report.total.to_string() +
  ",\"inliers\":" +
  report.inliers.to_string() +
  ",\"ratio\":" +
  report.inlier_ratio.to_string() +
  ",\"label\":\"" +
  report.label +
  "\"}"
}

///|
pub fn diagnostic_summary_line(report : DiagnosticReport) -> String {
  "inliers=" +
  report.inliers.to_string() +
  "/" +
  report.total.to_string() +
  " rms=" +
  report.rms.to_string() +
  " label=" +
  report.label
}

///|
pub fn diagnostic_report_merge(
  left : DiagnosticReport,
  right : DiagnosticReport,
) -> DiagnosticReport {
  make_diagnostic_report(
    [left.rms, right.rms],
    threshold=diagnostic_report_threshold(left).max(
      diagnostic_report_threshold(right),
    ),
  )
}

///|
pub fn diagnostic_report_scale(
  report : DiagnosticReport,
  scale : Double,
) -> DiagnosticReport {
  {
    total: report.total,
    inliers: report.inliers,
    outliers: report.outliers,
    inlier_ratio: report.inlier_ratio,
    mean_inlier: report.mean_inlier * scale,
    rms: report.rms * scale,
    maximum: report.maximum * scale,
    label: report.label,
  }
}

///|
pub fn diagnostic_report_is_empty(report : DiagnosticReport) -> Bool {
  report.total == 0
}

///|
pub fn diagnostic_report_inlier_fraction(report : DiagnosticReport) -> Double {
  report.inlier_ratio
}

///|
pub fn diagnostic_report_outlier_fraction(report : DiagnosticReport) -> Double {
  1.0 - report.inlier_ratio
}

///|
pub fn diagnostic_report_passes(
  report : DiagnosticReport,
  minimum_inliers : Int,
  maximum_rms : Double,
) -> Bool {
  report.inliers >= minimum_inliers && report.rms <= maximum_rms
}

///|
pub fn diagnostic_report_confidence(
  report : DiagnosticReport,
  iterations : Int,
) -> Double {
  let mut miss = 1.0
  let probability = (1.0 - report.inlier_ratio).max(0.0).min(1.0)
  for _ in 0..<iterations.max(0) {
    miss *= probability
  }
  1.0 - miss
}

///|
pub fn diagnostic_report_threshold(report : DiagnosticReport) -> Double {
  report.rms.max(report.mean_inlier).max(0.000000000001)
}
