package main

import "core:math/linalg"
import "core:math/rand"


Vec3 :: linalg.Vector3f64
Point3 :: Vec3

random_vec3_01 :: proc() -> Vec3 {
	return {rand.float64(), rand.float64(), rand.float64()}
}

random_vec3_range :: proc(min, max: f64) -> Vec3 {
	return {rand.float64_range(min, max), rand.float64_range(min, max), rand.float64_range(min, max)}
}

random_vec3 :: proc {
	random_vec3_01,
	random_vec3_range,
}

random_vec3_in_unit_sphere :: proc() -> Vec3 {
	for {
		p := random_vec3(-1, 1)
		if linalg.length2(p) < 1 do return p
	}
}

random_unit_vector :: proc() -> Vec3 {
	return linalg.normalize(random_vec3_in_unit_sphere())
}

random_vec3_on_hemisphere :: proc(normal: Vec3) -> Vec3 {
	on_unit_sphere := random_unit_vector()
	// if > 0, it's in the same hemisphere as the normal
	if linalg.dot(on_unit_sphere, normal) > 0 {
		return on_unit_sphere
	} else {
		return -on_unit_sphere
	}
}
