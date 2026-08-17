///|
test "consensus table ranks residual sets" {
  let table = ConsensusTable::new(threshold=1.0)
  table.observe([0.1, 0.2, 1.2, 3.0])
  table.observe([0.3, 0.4, 0.5, 0.6])
  assert_eq(table.best_inlier_count(), 4)
  assert_true(table.best_score() > 0.0)
  assert_eq(table.evaluated_models(), 2)
}

///|
test "consensus table handles empty residuals" {
  let table = ConsensusTable::new(threshold=0.5)
  table.observe([])
  assert_eq(table.best_inlier_count(), 0)
  assert_eq(table.evaluated_models(), 1)
}
