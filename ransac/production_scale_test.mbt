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
