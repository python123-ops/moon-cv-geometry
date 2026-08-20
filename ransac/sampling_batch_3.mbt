///|
/// Deterministic sample-set diagnostics for reproducible RANSAC runs.
pub(all) struct SampleBatchSummary {
  samples : Int
  dimensions : Int
  unique : Int
  duplicate_count : Int
  coverage : Double
  score : Double
} derive(Debug, Eq)

///|
pub fn sample_batch_unique(indices : ArrayView[Int]) -> Array[Int] {
  let result : Array[Int] = []
  for index in indices {
    if !result.contains(index) {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_batch_duplicate_count(indices : ArrayView[Int]) -> Int {
  indices.length() - sample_batch_unique(indices).length()
}

///|
pub fn sample_batch_minimum(indices : ArrayView[Int]) -> Int {
  if indices.length() == 0 {
    0
  } else {
    let mut result = indices[0]
    for index in indices {
      result = result.min(index)
    }
    result
  }
}

///|
pub fn sample_batch_maximum(indices : ArrayView[Int]) -> Int {
  let mut result = 0
  for index in indices {
    result = result.max(index)
  }
  result
}

///|
pub fn sample_batch_span(indices : ArrayView[Int]) -> Int {
  sample_batch_maximum(indices) - sample_batch_minimum(indices)
}

///|
pub fn sample_batch_coverage(
  indices : ArrayView[Int],
  population : Int,
) -> Double {
  if population <= 0 {
    0.0
  } else {
    sample_batch_unique(indices).length().to_double() / population.to_double()
  }
}

///|
pub fn sample_batch_is_valid(
  indices : ArrayView[Int],
  population : Int,
  minimum : Int,
) -> Bool {
  indices.length() >= minimum.max(0) &&
  sample_batch_duplicate_count(indices) == 0 &&
  sample_batch_minimum(indices) >= 0 &&
  sample_batch_maximum(indices) < population
}

///|
pub fn sample_batch_out_of_range(
  indices : ArrayView[Int],
  population : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for index in indices {
    if index < 0 || index >= population {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_batch_sorted(indices : ArrayView[Int]) -> Array[Int] {
  let result = indices.to_owned()
  result.sort()
  result
}

///|
pub fn sample_batch_delta(indices : ArrayView[Int]) -> Array[Int] {
  let sorted = sample_batch_sorted(indices)
  let result : Array[Int] = []
  if sorted.length() < 2 {
    return result
  }
  for i in 0..<(sorted.length() - 1) {
    result.push(sorted[i + 1] - sorted[i])
  }
  result
}

///|
pub fn sample_batch_mean_delta(indices : ArrayView[Int]) -> Double {
  let deltas = sample_batch_delta(indices)
  if deltas.length() == 0 {
    0.0
  } else {
    let mut total = 0
    for delta in deltas {
      total += delta
    }
    total.to_double() / deltas.length().to_double()
  }
}

///|
pub fn sample_batch_evenness(indices : ArrayView[Int]) -> Double {
  let deltas = sample_batch_delta(indices)
  if deltas.length() == 0 {
    0.0
  } else {
    let mean = sample_batch_mean_delta(indices)
    let mut error = 0.0
    for delta in deltas {
      error += (delta.to_double() - mean).abs()
    }
    1.0 / (1.0 + error / deltas.length().to_double())
  }
}

///|
pub fn sample_batch_summary(
  indices : ArrayView[Int],
  population : Int,
  dimensions : Int,
) -> SampleBatchSummary {
  let unique = sample_batch_unique(indices).length()
  let duplicates = indices.length() - unique
  let coverage = sample_batch_coverage(indices, population)
  {
    samples: indices.length(),
    dimensions: dimensions.max(0),
    unique,
    duplicate_count: duplicates,
    coverage,
    score: coverage *
    sample_batch_evenness(indices) *
    (if duplicates == 0 { 1.0 } else { 0.5 }),
  }
}

///|
pub fn sample_batch_intersection(
  left : ArrayView[Int],
  right : ArrayView[Int],
) -> Array[Int] {
  let result : Array[Int] = []
  for index in sample_batch_unique(left) {
    if right.contains(index) {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_batch_difference(
  left : ArrayView[Int],
  right : ArrayView[Int],
) -> Array[Int] {
  let result : Array[Int] = []
  for index in sample_batch_unique(left) {
    if !right.contains(index) {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_batch_union(
  left : ArrayView[Int],
  right : ArrayView[Int],
) -> Array[Int] {
  sample_batch_unique(left.to_owned() + right.to_owned())
}

///|
pub fn sample_batch_jaccard(
  left : ArrayView[Int],
  right : ArrayView[Int],
) -> Double {
  let intersection = sample_batch_intersection(left, right).length().to_double()
  let union = sample_batch_union(left, right).length().to_double()
  if union <= 0.0 {
    1.0
  } else {
    intersection / union
  }
}

///|
pub fn sample_batch_partition(
  indices : ArrayView[Int],
  partition_count : Int,
) -> Array[Array[Int]] {
  let result : Array[Array[Int]] = []
  let count = partition_count.max(1)
  for _ in 0..<count {
    result.push([])
  }
  for i in 0..<indices.length() {
    result[i % count].push(indices[i])
  }
  result
}

///|
pub fn sample_batch_partition_balance(
  indices : ArrayView[Int],
  partition_count : Int,
) -> Double {
  let parts = sample_batch_partition(indices, partition_count)
  if parts.length() == 0 {
    0.0
  } else {
    let mut minimum = parts[0].length()
    let mut maximum = parts[0].length()
    for part in parts {
      minimum = minimum.min(part.length())
      maximum = maximum.max(part.length())
    }
    if maximum == 0 {
      1.0
    } else {
      minimum.to_double() / maximum.to_double()
    }
  }
}

///|
pub fn sample_batch_stride(
  population : Int,
  stride : Int,
  offset : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  let step = stride.max(1)
  let start = offset.max(0)
  let end = population.max(start)
  for index in start..<end {
    if (index - start) % step == 0 {
      result.push(index)
    } else {
      ()
    }
  }
  result
}

///|
pub fn sample_batch_window(
  population : Int,
  start : Int,
  width : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  let first = start.max(0)
  let last = (first + width.max(0)).min(population.max(0))
  for index in first..<last {
    result.push(index)
  }
  result
}

///|
pub fn sample_batch_rotate(
  indices : ArrayView[Int],
  offset : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  if indices.length() == 0 {
    return result
  }
  for i in 0..<indices.length() {
    let raw = (i + offset) % indices.length()
    let index = if raw < 0 { raw + indices.length() } else { raw }
    result.push(indices[index])
  }
  result
}

///|
pub fn sample_batch_repeat(
  indices : ArrayView[Int],
  repetitions : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<repetitions.max(0) {
    for index in indices {
      result.push(index)
    }
  }
  result
}
