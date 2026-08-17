///|
pub fn depth_from_disparity(
  focal~ : Double,
  baseline~ : Double,
  disparity~ : Double,
) -> Double raise @core.GeometryError {
  if focal <= 0.0 || baseline <= 0.0 || disparity <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "stereo depth parameters must be positive",
    )
  }
  focal * baseline / disparity
}

///|
pub fn disparity_from_depth(
  focal~ : Double,
  baseline~ : Double,
  depth~ : Double,
) -> Double raise @core.GeometryError {
  if focal <= 0.0 || baseline <= 0.0 || depth <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "stereo depth parameters must be positive",
    )
  }
  focal * baseline / depth
}

///|
pub fn depth_uncertainty(
  focal~ : Double,
  baseline~ : Double,
  disparity~ : Double,
  disparity_error~ : Double,
) -> Double raise @core.GeometryError {
  let depth = depth_from_disparity(focal~, baseline~, disparity~)
  if disparity_error < 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "disparity error must be non-negative",
    )
  }
  depth * disparity_error / disparity
}

///|
pub fn normalized_depth(
  point : @core.Point3,
) -> Double raise @core.GeometryError {
  if point.z <= 0.0 {
    raise @core.GeometryError::DegenerateInput("point has invalid depth")
  }
  point.z
}

///|
pub fn project_depth_map(
  points : ArrayView[@core.Point3],
  intrinsics : CameraIntrinsics,
) -> Array[Double] raise @core.GeometryError {
  let result : Array[Double] = []
  for point in points {
    ignore(project_point(point, intrinsics))
    result.push(point.z)
  }
  result
}

///|
pub fn radial_distortion_scale(
  radius : Double,
  distortion : Distortion,
) -> Double {
  let r2 = radius * radius
  1.0 +
  distortion.k1 * r2 +
  distortion.k2 * r2 * r2 +
  distortion.k3 * r2 * r2 * r2
}

///|
pub fn radial_distortion_monotone(
  radius : Double,
  distortion : Distortion,
  samples? : Int = 16,
) -> Bool {
  if radius < 0.0 || samples < 2 {
    false
  } else {
    let mut previous = radial_distortion_scale(0.0, distortion)
    let mut result = true
    for i in 1..<=samples {
      let current = radial_distortion_scale(
        radius * Double::from_int(i) / Double::from_int(samples),
        distortion,
      )
      if current < previous {
        result = false
      }
      previous = current
    }
    result
  }
}

///|
pub fn pixel_ray_depth(
  pixel : @core.Point2,
  intrinsics : CameraIntrinsics,
  depth : Double,
) -> @core.Point3 raise @core.GeometryError {
  if depth <= 0.0 {
    raise @core.GeometryError::DegenerateInput("depth must be positive")
  }
  let n = pixel_to_normalized(pixel, intrinsics)
  @core.Point3::new(x=n.x * depth, y=n.y * depth, z=depth)
}
