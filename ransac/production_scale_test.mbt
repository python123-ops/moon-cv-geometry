///|
test "deterministic sampling covers bounded subsets" {
  let sample = deterministic_sample_indices(
    population=20,
    sample_size=5,
    seed=7,
  )
  assert_eq(sample.length(), 5)
  assert_true(sample[0] >= 0 && sample[0] < 20)
  assert_eq(unique_index_count(sample), 5)
}

///|
test "model diagnostics classify consensus quality" {
  let report = make_diagnostic_report([0.1, 0.2, 0.4, 3.0], threshold=0.5)
  assert_eq(report.inliers, 3)
  assert_true(report.inlier_ratio > 0.7)
  assert_eq(report.label, "good")
}

///|
test "adaptive stopping reacts to stable consensus" {
  let state = AdaptiveStopState::new(minimum_iterations=3, target_ratio=0.8)
  state.observe(inliers=9, total=10)
  state.observe(inliers=9, total=10)
  state.observe(inliers=9, total=10)
  assert_true(state.should_stop())
}

///|
test "robust losses and consensus pipeline rank candidates" {
  assert_true(
    huber_loss2(residual=0.2, delta=1.0) < huber_loss2(residual=2.0, delta=1.0),
  )
  let candidates = evaluate_consensus_candidates(
    [[0.1, 0.2, 0.3], [0.1, 2.0, 3.0]],
    threshold=0.5,
  )
  assert_eq(candidates[0].inliers, 3)
  assert_true(select_best_candidate(candidates).inliers == 3)
}

///|
test "diagnostic serialization contains stable fields" {
  let report = make_diagnostic_report([0.1, 0.2], threshold=0.5)
  let row = diagnostic_csv_row(report)
  assert_true(row.contains("2"))
  assert_true(diagnostic_quality_bucket(report) == 2)
}

///|
test "model selection and sample diagnostics are reproducible" {
  let reports = [
    make_model_report(
      iterations=10,
      inliers=8,
      total=10,
      score=0.8,
      converged=true,
    ),
    make_model_report(
      iterations=20,
      inliers=5,
      total=10,
      score=0.5,
      converged=false,
    ),
  ]
  assert_eq(model_report_best_index(reports, 0.5, 4), 0)
  let sample = [0, 2, 4, 6]
  assert_eq(sample_batch_duplicate_count(sample), 0)
  assert_true(sample_batch_coverage(sample, 8) > 0.0)
  assert_eq(sample_batch_window(8, 2, 3).length(), 3)
}

///|
test "diagnostic series exports health and confidence" {
  let reports = [make_diagnostic_report([0.1, 0.2, 0.3], threshold=0.5)]
  assert_true(diagnostic_series_quality(reports, 2, 0.5) > 0.0)
  assert_true(diagnostic_reports_json(reports).contains("inliers"))
  assert_true(diagnostic_report_confidence(reports[0], 5) >= 0.0)
}

///|
test "diagnostic and sampling APIs cover production report paths" {
  let report = make_diagnostic_report([0.1, 0.2, 0.3, 1.5], threshold=0.5)
  let reports = [report, diagnostic_report_scale(report, 2.0)]
  ignore(diagnostic_summary_line(report))
  ignore(diagnostic_report_merge(report, report))
  ignore(diagnostic_report_inlier_fraction(report))
  ignore(diagnostic_report_outlier_fraction(report))
  ignore(diagnostic_report_passes(report, 2, 1.0))
  ignore(diagnostic_report_threshold(report))
  ignore(diagnostic_series_mean(reports))
  ignore(diagnostic_series_maximum(reports))
  ignore(diagnostic_series_minimum(reports))
  ignore(diagnostic_series_improvement(reports))
  ignore(diagnostic_series_inlier_mean(reports))
  ignore(diagnostic_series_stable(reports, 10.0))
  ignore(diagnostic_series_pass_count(reports, 2, 2.0))
  ignore(diagnostic_series_pass_ratio(reports, 2, 2.0))
  ignore(diagnostic_series_buckets(reports))
  ignore(diagnostic_series_last(reports))
  ignore(diagnostic_series_best(reports))
  ignore(diagnostic_series_window(reports, 0, 1))
  ignore(diagnostic_series_scale(reports, 0.5))
  ignore(diagnostic_series_labels(reports))
  ignore(diagnostic_series_summary(reports))
  ignore(diagnostic_series_quality(reports, 2, 2.0))
  let model_reports = [
    make_model_report(
      iterations=10,
      inliers=8,
      total=10,
      score=0.8,
      converged=true,
    ),
  ]
  ignore(model_report_rank(model_reports, 0.5, 4))
  ignore(model_report_best(model_reports, 0.5, 4))
  ignore(model_selection_summary(model_reports, 0.5, 4))
  ignore(model_report_filter_converged(model_reports))
  ignore(model_report_filter_ratio(model_reports, 0.5))
  ignore(model_report_filter_inliers(model_reports, 4))
  ignore(model_report_sort_by_score(model_reports))
  ignore(model_report_sort_by_ratio(model_reports))
  ignore(model_report_consensus_ratio(model_reports))
  ignore(model_report_consensus_spread(model_reports))
  ignore(model_report_stability(model_reports, 1.0))
  ignore(model_report_merge_all(model_reports))
  ignore(model_report_reliability(model_reports[0], 100))
  ignore(model_report_bucket_counts(model_reports))
  ignore(model_reports_to_csv(model_reports))
  ignore(model_report_expected_success(model_reports[0], 5.0))
  ignore(model_report_budget(model_reports[0], 100))
  let indices = [0, 2, 4, 6]
  ignore(sample_batch_minimum(indices))
  ignore(sample_batch_maximum(indices))
  ignore(sample_batch_span(indices))
  ignore(sample_batch_is_valid(indices, 8, 4))
  ignore(sample_batch_out_of_range(indices, 8))
  ignore(sample_batch_sorted(indices))
  ignore(sample_batch_delta(indices))
  ignore(sample_batch_mean_delta(indices))
  ignore(sample_batch_evenness(indices))
  ignore(sample_batch_summary(indices, 8, 2))
  ignore(sample_batch_intersection(indices, [1, 2, 3]))
  ignore(sample_batch_difference(indices, [1, 2, 3]))
  ignore(sample_batch_union(indices, [1, 2, 3]))
  ignore(sample_batch_jaccard(indices, [1, 2, 3]))
  ignore(sample_batch_partition(indices, 2))
  ignore(sample_batch_partition_balance(indices, 2))
  ignore(sample_batch_stride(10, 2, 0))
  ignore(sample_batch_rotate(indices, 1))
  ignore(sample_batch_repeat(indices, 2))
}
