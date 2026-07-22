///|
fn main raise {
  let intrinsics = @camera.CameraIntrinsics::new(
    fx=500.0,
    fy=500.0,
    cx=320.0,
    cy=240.0,
  )
  let p = @core.Point3::new(x=1.0, y=2.0, z=4.0)
  let pixel = @camera.project_point(p, intrinsics)
  println("projected pixel: \{pixel.x}, \{pixel.y}")
}
