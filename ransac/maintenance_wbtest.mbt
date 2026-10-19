///|
test "four point samples contain distinct in-range indices" {
  for population in 4..<25 {
    for seed in [0U, 1U, 7U, 4294967295U] {
      for iteration in 0..<64 {
        let (a, b, c, d) = sample_four(population, seed, iteration)
        let indices = [a, b, c, d]
        for i in 0..<4 {
          assert_true(indices[i] >= 0 && indices[i] < population)
          for j in (i + 1)..<4 {
            assert_true(indices[i] != indices[j])
          }
        }
      }
    }
  }
}
