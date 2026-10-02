///|
/// Ranked consensus record for repeated model evaluation.
pub(all) struct ConsensusRecord {
  inlier_count : Int
  score : Double
  residual_sum : Double
} derive(Debug, Eq)

///|
pub(all) struct ConsensusTable {
  threshold : Double
  records : Array[ConsensusRecord]
}

///|
pub fn ConsensusTable::new(threshold~ : Double) -> ConsensusTable {
  { threshold: threshold.max(0.0), records: [], }
}

///|
pub fn ConsensusTable::observe(
  table : ConsensusTable,
  residuals : ArrayView[Double],
) -> Unit {
  let mut count = 0
  let mut score = 0.0
  let mut sum = 0.0
  for residual in residuals {
    let error = @core.abs(residual)
    sum += error
    if error <= table.threshold {
      count += 1
      score += table.threshold - error
    }
  }
  table.records.push({ inlier_count: count, score, residual_sum: sum, })
}

///|
pub fn ConsensusTable::evaluated_models(table : ConsensusTable) -> Int {
  table.records.length()
}

///|
pub fn ConsensusTable::best_inlier_count(table : ConsensusTable) -> Int {
  let mut best = 0
  for record in table.records {
    best = best.max(record.inlier_count)
  }
  best
}

///|
pub fn ConsensusTable::best_score(table : ConsensusTable) -> Double {
  let mut best = 0.0
  for record in table.records {
    best = best.max(record.score)
  }
  best
}

///|
pub fn ConsensusTable::best_record(table : ConsensusTable) -> ConsensusRecord? {
  if table.records.length() == 0 {
    return None
  }
  let mut best = table.records[0]
  for record in table.records[1:] {
    if record.inlier_count > best.inlier_count ||
      (record.inlier_count == best.inlier_count && record.score > best.score) {
      best = record
    }
  }
  Some(best)
}

///|
pub fn ConsensusTable::clear(table : ConsensusTable) -> Unit {
  table.records.clear()
}

///|
pub fn consensus_mask(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for residual in residuals {
    result.push(@core.abs(residual) <= threshold)
  }
  result
}
