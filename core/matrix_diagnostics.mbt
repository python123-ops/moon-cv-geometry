///|
pub fn Mat3::trace(matrix : Mat3) -> Double {
  matrix.m00 + matrix.m11 + matrix.m22
}

///|
pub fn Mat3::power(matrix : Mat3, exponent : Int) -> Mat3 {
  if exponent <= 0 {
    identity3()
  } else {
    for value = identity3(), i = 0; i < exponent; {
      continue value.mul(matrix), i + 1
    } nobreak {
      value
    }
  }
}

///|
pub fn Mat3::hadamard(a : Mat3, b : Mat3) -> Mat3 {
  mat3_from_rows(
    (a.m00 * b.m00, a.m01 * b.m01, a.m02 * b.m02),
    (a.m10 * b.m10, a.m11 * b.m11, a.m12 * b.m12),
    (a.m20 * b.m20, a.m21 * b.m21, a.m22 * b.m22),
  )
}

///|
pub fn Mat3::is_symmetric(
  matrix : Mat3,
  tolerance? : Double = 0.000001,
) -> Bool {
  abs(matrix.m01 - matrix.m10) <= tolerance &&
  abs(matrix.m02 - matrix.m20) <= tolerance &&
  abs(matrix.m12 - matrix.m21) <= tolerance
}

///|
pub fn Mat3::diagonal(matrix : Mat3) -> Vec3 {
  Vec3::new(x=matrix.m00, y=matrix.m11, z=matrix.m22)
}

///|
pub fn Mat3::off_diagonal_norm(matrix : Mat3) -> Double {
  (matrix.m01 * matrix.m01 +
  matrix.m02 * matrix.m02 +
  matrix.m10 * matrix.m10 +
  matrix.m12 * matrix.m12 +
  matrix.m20 * matrix.m20 +
  matrix.m21 * matrix.m21).sqrt()
}

///|
pub fn matrix3_from_diagonal(diagonal : Vec3) -> Mat3 {
  mat3_from_rows(
    (diagonal.x, 0.0, 0.0),
    (0.0, diagonal.y, 0.0),
    (0.0, 0.0, diagonal.z),
  )
}

///|
pub fn matrix3_is_finite(matrix : Mat3) -> Bool {
  matrix.m00 == matrix.m00 &&
  matrix.m01 == matrix.m01 &&
  matrix.m02 == matrix.m02 &&
  matrix.m10 == matrix.m10 &&
  matrix.m11 == matrix.m11 &&
  matrix.m12 == matrix.m12 &&
  matrix.m20 == matrix.m20 &&
  matrix.m21 == matrix.m21 &&
  matrix.m22 == matrix.m22
}
