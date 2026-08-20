///|
/// Linear interpolation and clamped interpolation helpers.
pub fn lerp2(left : Double, right : Double, amount : Double) -> Double {
  left + (right - left) * amount
}

///|
pub fn lerp2_clamped(left : Double, right : Double, amount : Double) -> Double {
  lerp2(left, right, amount.max(0.0).min(1.0))
}

///|
pub fn inverse_lerp2(left : Double, right : Double, value : Double) -> Double {
  if (right - left).abs() <= 0.000000000001 {
    0.0
  } else {
    (value - left) / (right - left)
  }
}

///|
pub fn remap2(
  value : Double,
  source_min : Double,
  source_max : Double,
  target_min : Double,
  target_max : Double,
) -> Double {
  lerp2(target_min, target_max, inverse_lerp2(source_min, source_max, value))
}

///|
pub fn smoothstep2(amount : Double) -> Double {
  let t = amount.max(0.0).min(1.0)
  t * t * (3.0 - 2.0 * t)
}

///|
pub fn smootherstep2(amount : Double) -> Double {
  let t = amount.max(0.0).min(1.0)
  t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

///|
pub fn cosine_interpolation2(
  left : Double,
  right : Double,
  amount : Double,
) -> Double {
  let t = (1.0 - @math.cos(amount * @math.PI)) / 2.0
  lerp2(left, right, t)
}

///|
pub fn cubic_interpolation2(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  amount : Double,
) -> Double {
  let t2 = amount * amount
  let t3 = t2 * amount
  0.5 *
  (
    2.0 * b +
    (-a + c) * amount +
    (2.0 * a - 5.0 * b + 4.0 * c - d) * t2 +
    (-a + 3.0 * b - 3.0 * c + d) * t3
  )
}

///|
pub fn cubic_hermite2(
  p0 : Double,
  p1 : Double,
  tangent0 : Double,
  tangent1 : Double,
  amount : Double,
) -> Double {
  let t2 = amount * amount
  let t3 = t2 * amount
  (2.0 * t3 - 3.0 * t2 + 1.0) * p0 +
  (t3 - 2.0 * t2 + amount) * tangent0 +
  (-2.0 * t3 + 3.0 * t2) * p1 +
  (t3 - t2) * tangent1
}

///|
pub fn cubic_hermite_sample(
  p0 : Double,
  p1 : Double,
  tangent0 : Double,
  tangent1 : Double,
  count~ : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if count <= 0 {
    return result
  }
  for i in 0..<count {
    let amount = if count == 1 {
      0.0
    } else {
      i.to_double() / (count - 1).to_double()
    }
    result.push(cubic_hermite2(p0, p1, tangent0, tangent1, amount))
  }
  result
}

///|
pub fn catmull_rom_sample(
  points : ArrayView[Double],
  count_per_segment : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if points.length() == 0 {
    return result
  }
  if points.length() == 1 {
    result.push(points[0])
    return result
  }
  for i in 0..<(points.length() - 1) {
    let a = if i == 0 { points[i] } else { points[i - 1] }
    let b = points[i]
    let c = points[i + 1]
    let d = if i + 2 >= points.length() { c } else { points[i + 2] }
    for step in 0..<count_per_segment.max(1) {
      result.push(
        cubic_interpolation2(
          a,
          b,
          c,
          d,
          step.to_double() / count_per_segment.max(1).to_double(),
        ),
      )
    }
  }
  result.push(points[points.length() - 1])
  result
}

///|
pub fn bilerp2(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  x : Double,
  y : Double,
) -> Double {
  lerp2(lerp2(a, b, x), lerp2(c, d, x), y)
}

///|
pub fn trilerp2(
  corners : ArrayView[Double],
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  if corners.length() < 8 {
    0.0
  } else {
    let lower = bilerp2(corners[0], corners[1], corners[2], corners[3], x, y)
    let upper = bilerp2(corners[4], corners[5], corners[6], corners[7], x, y)
    lerp2(lower, upper, z)
  }
}

///|
pub fn interpolate_array(values : ArrayView[Double], amount : Double) -> Double {
  if values.length() == 0 {
    0.0
  } else if values.length() == 1 {
    values[0]
  } else {
    let position = amount.max(0.0).min(1.0) * (values.length() - 1).to_double()
    let lower = position.floor().to_int()
    let upper = position.ceil().to_int().min(values.length() - 1)
    lerp2(values[lower], values[upper], position - lower.to_double())
  }
}

///|
pub fn resample_array(values : ArrayView[Double], count : Int) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<count.max(0) {
    let amount = if count <= 1 {
      0.0
    } else {
      i.to_double() / (count - 1).to_double()
    }
    result.push(interpolate_array(values, amount))
  }
  result
}

///|
pub fn finite_difference2(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() < 2 {
    return result
  }
  for i in 0..<(values.length() - 1) {
    result.push(values[i + 1] - values[i])
  }
  result
}

///|
pub fn second_difference2(values : ArrayView[Double]) -> Array[Double] {
  finite_difference2(finite_difference2(values))
}

///|
pub fn interpolation_monotonic(values : ArrayView[Double]) -> Bool {
  for i in 1..<values.length() {
    if values[i] < values[i - 1] {
      return false
    }
  }
  true
}

///|
pub fn interpolation_range(values : ArrayView[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut minimum = values[0]
    let mut maximum = values[0]
    for value in values {
      minimum = minimum.min(value)
      maximum = maximum.max(value)
    }
    maximum - minimum
  }
}
