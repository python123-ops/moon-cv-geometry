///|
pub fn smoothstep(edge0~ : Double, edge1~ : Double, x~ : Double) -> Double {
  if edge0 == edge1 {
    if x < edge0 {
      0.0
    } else {
      1.0
    }
  } else {
    let t = clamp((x - edge0) / (edge1 - edge0), lo=0.0, hi=1.0)
    t * t * (3.0 - 2.0 * t)
  }
}

///|
pub fn smootherstep(edge0~ : Double, edge1~ : Double, x~ : Double) -> Double {
  let t = clamp((x - edge0) / (edge1 - edge0), lo=0.0, hi=1.0)
  t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

///|
pub fn hermite_scalar(
  p0~ : Double,
  p1~ : Double,
  tangent0~ : Double,
  tangent1~ : Double,
  amount~ : Double,
) -> Double {
  let t2 = amount * amount
  let t3 = t2 * amount
  (2.0 * t3 - 3.0 * t2 + 1.0) * p0 +
  (t3 - 2.0 * t2 + amount) * tangent0 +
  (-2.0 * t3 + 3.0 * t2) * p1 +
  (t3 - t2) * tangent1
}

///|
pub fn hermite_point2(
  p0 : Point2,
  p1 : Point2,
  tangent0 : Vec2,
  tangent1 : Vec2,
  amount : Double,
) -> Point2 {
  Point2::new(
    x=hermite_scalar(
      p0=p0.x,
      p1=p1.x,
      tangent0=tangent0.x,
      tangent1=tangent1.x,
      amount~,
    ),
    y=hermite_scalar(
      p0=p0.y,
      p1=p1.y,
      tangent0=tangent0.y,
      tangent1=tangent1.y,
      amount~,
    ),
  )
}

///|
pub fn hermite_point3(
  p0 : Point3,
  p1 : Point3,
  tangent0 : Vec3,
  tangent1 : Vec3,
  amount : Double,
) -> Point3 {
  Point3::new(
    x=hermite_scalar(
      p0=p0.x,
      p1=p1.x,
      tangent0=tangent0.x,
      tangent1=tangent1.x,
      amount~,
    ),
    y=hermite_scalar(
      p0=p0.y,
      p1=p1.y,
      tangent0=tangent0.y,
      tangent1=tangent1.y,
      amount~,
    ),
    z=hermite_scalar(
      p0=p0.z,
      p1=p1.z,
      tangent0=tangent0.z,
      tangent1=tangent1.z,
      amount~,
    ),
  )
}

///|
pub fn resample_polyline(
  points : ArrayView[Point2],
  samples~ : Int,
) -> Array[Point2] raise GeometryError {
  if points.length() < 2 || samples < 2 {
    raise GeometryError::NotEnoughPoints(
      "resampling needs a polyline and two samples",
    )
  }
  let total = polyline_length(points)
  if total <= 0.0 {
    raise GeometryError::DegenerateInput("polyline has zero length")
  }
  let result : Array[Point2] = []
  for sample in 0..<samples {
    let target = total *
      Double::from_int(sample) /
      Double::from_int(samples - 1)
    let mut traversed = 0.0
    let mut found = points[0]
    for i in 1..<points.length() {
      let segment = points[i].minus(points[i - 1]).norm()
      if target <= traversed + segment || i == points.length() - 1 {
        let amount = if segment <= 0.0 {
          0.0
        } else {
          (target - traversed) / segment
        }
        found = point2_lerp(points[i - 1], points[i], amount)
        break
      }
      traversed += segment
    }
    result.push(found)
  }
  result
}

///|
pub fn interpolate_table(
  x : Double,
  xs : ArrayView[Double],
  ys : ArrayView[Double],
) -> Double raise GeometryError {
  if xs.length() != ys.length() || xs.length() == 0 {
    raise GeometryError::NotEnoughPoints(
      "interpolation table needs paired values",
    )
  }
  if xs.length() == 1 {
    ys[0]
  } else {
    let mut index = 0
    while index + 1 < xs.length() && x > xs[index + 1] {
      index += 1
    }
    let next = if index + 1 < xs.length() { index + 1 } else { index }
    if next == index {
      ys[index]
    } else {
      linear_interpolate(
        ys[index],
        ys[next],
        (x - xs[index]) / (xs[next] - xs[index]),
      )
    }
  }
}

///|
pub fn cumulative_lengths(points : ArrayView[Point2]) -> Array[Double] {
  let result : Array[Double] = []
  let mut total = 0.0
  result.push(total)
  for i in 1..<points.length() {
    total += points[i].minus(points[i - 1]).norm()
    result.push(total)
  }
  result
}
