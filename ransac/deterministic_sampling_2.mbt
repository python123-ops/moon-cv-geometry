///|
/// A small deterministic integer generator for reproducible RANSAC sampling.
pub(all) struct DeterministicSampler {
  mut state : Int
}

///|
pub fn DeterministicSampler::new(seed~ : Int) -> DeterministicSampler {
  { state: if seed == 0 { 1 } else { seed.abs() }, }
}

///|
pub fn DeterministicSampler::next(
  sampler : DeterministicSampler,
  bound : Int,
) -> Int {
  sampler.state = (sampler.state * 1103515245 + 12345) % 2147483647
  if bound <= 0 {
    0
  } else {
    sampler.state.abs() % bound
  }
}

///|
pub fn deterministic_sample_indices(
  population~ : Int,
  sample_size~ : Int,
  seed~ : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  let sampler = DeterministicSampler::new(seed~)
  let target = sample_size.max(0).min(population.max(0))
  while result.length() < target {
    let candidate = sampler.next(population)
    if !result.contains(candidate) {
      result.push(candidate)
    }
  }
  result
}

///|
pub fn unique_index_count(indices : ArrayView[Int]) -> Int {
  let unique : Array[Int] = []
  for index in indices {
    if !unique.contains(index) {
      unique.push(index)
    }
  }
  unique.length()
}

///|
pub fn sorted_indices(indices : ArrayView[Int]) -> Array[Int] {
  let result = indices.to_owned()
  result.sort()
  result
}

///|
pub fn sample_complement(
  population : Int,
  selected : ArrayView[Int],
) -> Array[Int] {
  let result : Array[Int] = []
  for index in 0..<population.max(0) {
    if !selected.contains(index) {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_union(
  left : ArrayView[Int],
  right : ArrayView[Int],
) -> Array[Int] {
  let result : Array[Int] = []
  for index in left {
    if !result.contains(index) {
      result.push(index)
    }
  }
  for index in right {
    if !result.contains(index) {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_intersection(
  left : ArrayView[Int],
  right : ArrayView[Int],
) -> Array[Int] {
  let result : Array[Int] = []
  for index in left {
    if right.contains(index) && !result.contains(index) {
      result.push(index)
    }
  }
  result
}

///|
pub fn sample_is_valid(
  indices : ArrayView[Int],
  population : Int,
  sample_size : Int,
) -> Bool {
  indices.length() == sample_size &&
  unique_index_count(indices) == sample_size &&
  for_all_indices(indices, fn(index) { index >= 0 && index < population })
}

///|
fn for_all_indices(indices : ArrayView[Int], predicate : (Int) -> Bool) -> Bool {
  for index in indices {
    if !predicate(index) {
      return false
    }
  }
  true
}

///|
pub fn sample_batches(
  population : Int,
  sample_size : Int,
  count : Int,
  seed : Int,
) -> Array[Array[Int]] {
  let result : Array[Array[Int]] = []
  let mut current_seed = seed
  for _ in 0..<count.max(0) {
    result.push(
      deterministic_sample_indices(population~, sample_size~, seed=current_seed),
    )
    current_seed += 1
  }
  result
}

///|
pub fn sampling_coverage(
  batches : ArrayView[Array[Int]],
  population : Int,
) -> Double {
  let covered : Array[Int] = []
  for batch in batches {
    for index in batch {
      if !covered.contains(index) {
        covered.push(index)
      }
    }
  }
  if population <= 0 {
    0.0
  } else {
    covered.length().to_double() / population.to_double()
  }
}

///|
pub fn sample_frequency(
  batches : ArrayView[Array[Int]],
  population : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<population.max(0) {
    result.push(0)
  }
  for batch in batches {
    for index in batch {
      if index >= 0 && index < result.length() {
        result[index] += 1
      }
    }
  }
  result
}
