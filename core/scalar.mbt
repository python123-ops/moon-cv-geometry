///|
pub fn abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
pub fn square(x : Double) -> Double {
  x * x
}

///|
pub fn almost_equal(
  a : Double,
  b : Double,
  eps? : Double = 0.000000001,
) -> Bool {
  abs(a - b) <= eps
}

///|
pub fn clamp(x : Double, lo~ : Double, hi~ : Double) -> Double {
  if x < lo {
    lo
  } else if x > hi {
    hi
  } else {
    x
  }
}
