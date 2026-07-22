///|
fn main {
  let distortion = @camera.Distortion::brown_conrady(
    k1=0.1,
    k2=-0.02,
    p1=0.001,
    p2=-0.001,
  )
  let normalized = @core.Point2::new(x=0.2, y=-0.1)
  let distorted = @camera.distort_point(normalized, distortion)
  let recovered = @camera.undistort_point_iterative(
    distorted,
    distortion,
    iterations=8,
  )
  println("distorted: \{distorted.x}, \{distorted.y}")
  println("recovered: \{recovered.x}, \{recovered.y}")
}
