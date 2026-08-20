///|
/// Difference between distorted and ideal normalized image coordinates.
pub fn distortion_displacement(
  point : @core.Point2,
  distortion : Distortion,
) -> @core.Vec2 {
  let distorted = distort_point(point, distortion)
  @core.Vec2::new(x=distorted.x - point.x, y=distorted.y - point.y)
}

///|
pub fn distortion_displacement_field(
  points : ArrayView[@core.Point2],
  distortion : Distortion,
) -> Array[@core.Vec2] {
  let result : Array[@core.Vec2] = []
  for point in points {
    result.push(distortion_displacement(point, distortion))
  }
  result
}

///|
pub fn distortion_magnitude_field(
  points : ArrayView[@core.Point2],
  distortion : Distortion,
) -> Array[Double] {
  let result : Array[Double] = []
  for displacement in distortion_displacement_field(points, distortion) {
    result.push(displacement.norm())
  }
  result
}

///|
pub fn distortion_rms(
  points : ArrayView[@core.Point2],
  distortion : Distortion,
) -> Double {
  let values = distortion_magnitude_field(points, distortion)
  if values.length() == 0 {
    0.0
  } else {
    let mut sum = 0.0
    for value in values {
      sum += value * value
    }
    (sum / values.length().to_double()).sqrt()
  }
}

///|
pub fn distortion_max(
  points : ArrayView[@core.Point2],
  distortion : Distortion,
) -> Double {
  let mut result = 0.0
  for value in distortion_magnitude_field(points, distortion) {
    result = result.max(value)
  }
  result
}

///|
pub fn distortion_is_negligible(
  points : ArrayView[@core.Point2],
  distortion : Distortion,
  tolerance : Double,
) -> Bool {
  distortion_max(points, distortion) <= tolerance
}

///|
pub fn distortion_radial_profile(
  radii : ArrayView[Double],
  distortion : Distortion,
) -> Array[Double] {
  let result : Array[Double] = []
  for radius in radii {
    let squared = radius * radius
    result.push(
      distortion.k1 * squared +
      distortion.k2 * squared * squared +
      distortion.k3 * squared * squared * squared,
    )
  }
  result
}

///|
pub fn distortion_corrected_radii(
  radii : ArrayView[Double],
  distortion : Distortion,
) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<radii.length() {
    let radius = radii[i]
    let correction = distortion_radial_profile([radius], distortion)[0]
    result.push(radius * (1.0 + correction))
  }
  result
}

///|
pub fn distortion_parameter_norm(distortion : Distortion) -> Double {
  (distortion.k1 * distortion.k1 +
  distortion.k2 * distortion.k2 +
  distortion.p1 * distortion.p1 +
  distortion.p2 * distortion.p2 +
  distortion.k3 * distortion.k3).sqrt()
}

///|
pub fn blend_distortion(
  a : Distortion,
  b : Distortion,
  amount : Double,
) -> Distortion {
  let t = amount.max(0.0).min(1.0)
  Distortion::brown_conrady(
    k1=a.k1 * (1.0 - t) + b.k1 * t,
    k2=a.k2 * (1.0 - t) + b.k2 * t,
    p1=a.p1 * (1.0 - t) + b.p1 * t,
    p2=a.p2 * (1.0 - t) + b.p2 * t,
    k3=a.k3 * (1.0 - t) + b.k3 * t,
  )
}

///|
pub fn distortion_parameter_distance(a : Distortion, b : Distortion) -> Double {
  distortion_parameter_norm(blend_distortion(a, b, 0.0)) +
  distortion_parameter_norm(blend_distortion(a, b, 1.0)) -
  2.0 * distortion_parameter_norm(blend_distortion(a, b, 0.5))
}
