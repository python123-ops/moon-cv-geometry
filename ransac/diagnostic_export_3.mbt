///|
/// Compact diagnostic exports used by CI benchmark artifacts.
pub fn diagnostic_report_header() -> String {
  "total,inliers,outliers,inlier_ratio,mean_inlier,rms,maximum,label"
}

///|
pub fn diagnostic_report_csv_full(report : DiagnosticReport) -> String {
  report.total.to_string() +
  "," +
  report.inliers.to_string() +
  "," +
  report.outliers.to_string() +
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
pub fn diagnostic_report_json_full(report : DiagnosticReport) -> String {
  "{\"total\":" +
  report.total.to_string() +
  ",\"inliers\":" +
  report.inliers.to_string() +
  ",\"outliers\":" +
  report.outliers.to_string() +
  ",\"ratio\":" +
  report.inlier_ratio.to_string() +
  ",\"rms\":" +
  report.rms.to_string() +
  ",\"label\":\"" +
  report.label +
  "\"}"
}

///|
pub fn diagnostic_report_error_ratio(report : DiagnosticReport) -> Double {
  if report.total <= 0 {
    0.0
  } else {
    report.outliers.to_double() / report.total.to_double()
  }
}

///|
pub fn diagnostic_report_signal_to_error(report : DiagnosticReport) -> Double {
  report.inlier_ratio / (1.0 + diagnostic_report_error_ratio(report))
}

///|
pub fn diagnostic_report_acceptable(
  report : DiagnosticReport,
  minimum_ratio : Double,
  maximum_rms : Double,
) -> Bool {
  report.inlier_ratio >= minimum_ratio && report.rms <= maximum_rms
}

///|
pub fn diagnostic_report_margin(
  report : DiagnosticReport,
  minimum_ratio : Double,
  maximum_rms : Double,
) -> Double {
  (report.inlier_ratio - minimum_ratio).min(maximum_rms - report.rms)
}

///|
pub fn diagnostic_report_health(
  report : DiagnosticReport,
  minimum_ratio : Double,
  maximum_rms : Double,
) -> Double {
  let ratio = (report.inlier_ratio / minimum_ratio.max(0.000000000001)).min(1.0)
  let rms = (maximum_rms / report.rms.max(0.000000000001)).min(1.0)
  ratio * rms
}

///|
pub fn diagnostic_report_health_label(
  report : DiagnosticReport,
  minimum_ratio : Double,
  maximum_rms : Double,
) -> String {
  let health = diagnostic_report_health(report, minimum_ratio, maximum_rms)
  if health >= 0.8 {
    "healthy"
  } else if health >= 0.5 {
    "degraded"
  } else {
    "failed"
  }
}

///|
pub fn diagnostic_reports_csv(reports : ArrayView[DiagnosticReport]) -> String {
  let mut result = diagnostic_report_header()
  for report in reports {
    result += "\n" + diagnostic_report_csv_full(report)
  }
  result
}

///|
pub fn diagnostic_reports_json(reports : ArrayView[DiagnosticReport]) -> String {
  let mut result = "["
  for i in 0..<reports.length() {
    if i > 0 {
      result += ","
    }
    result += diagnostic_report_json_full(reports[i])
  }
  result + "]"
}
