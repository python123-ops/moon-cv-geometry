///|
pub(all) struct StereoPair {
  left : CameraIntrinsics
  right : CameraIntrinsics
  baseline : Double
} derive(Debug, Eq)

///|
pub fn StereoPair::new(
  left~ : CameraIntrinsics,
  right~ : CameraIntrinsics,
  baseline~ : Double,
) -> StereoPair raise @core.GeometryError {
  if !left.valid() || !right.valid() || baseline <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "stereo pair parameters are invalid",
    )
  }
  { left, right, baseline }
}

///|
pub fn StereoPair::depth(
  pair : StereoPair,
  disparity : Double,
) -> Double raise @core.GeometryError {
  depth_from_disparity(
    focal=pair.left.focal_mean(),
    baseline=pair.baseline,
    disparity~,
  )
}

///|
pub fn StereoPair::disparity(
  pair : StereoPair,
  depth : Double,
) -> Double raise @core.GeometryError {
  disparity_from_depth(
    focal=pair.left.focal_mean(),
    baseline=pair.baseline,
    depth~,
  )
}

///|
pub fn StereoPair::depth_point(
  pair : StereoPair,
  left_pixel : @core.Point2,
  disparity : Double,
) -> @core.Point3 raise @core.GeometryError {
  let depth = pair.depth(disparity)
  pixel_ray_depth(left_pixel, pair.left, depth)
}

///|
pub fn StereoPair::valid_disparity(
  pair : StereoPair,
  disparity : Double,
  minimum? : Double = 0.1,
) -> Bool {
  pair.baseline > 0.0 && disparity >= minimum
}

///|
pub fn stereo_depths(
  pair : StereoPair,
  disparities : ArrayView[Double],
) -> Array[Double] raise @core.GeometryError {
  let result : Array[Double] = []
  for disparity in disparities {
    result.push(pair.depth(disparity))
  }
  result
}

///|
pub fn stereo_depth_error(
  pair : StereoPair,
  disparity : Double,
  disparity_error : Double,
) -> Double raise @core.GeometryError {
  depth_uncertainty(
    focal=pair.left.focal_mean(),
    baseline=pair.baseline,
    disparity~,
    disparity_error~,
  )
}
