package main

import "core:fmt"
import "core:math/linalg"
import "core:strings"


Color :: Vec3

linear_to_byte :: proc(color: Color) -> (out_r, out_g, out_b: byte) {
	r := linear_to_gamma(color.r)
	g := linear_to_gamma(color.g)
	b := linear_to_gamma(color.b)

	// Write the translated [0,255] value of each color component.
	intensity := Interval{0.000, 0.999}
	out_r = byte(int(256 * interval_clamp(intensity, r)))
	out_g = byte(int(256 * interval_clamp(intensity, g)))
	out_b = byte(int(256 * interval_clamp(intensity, b)))

	return
}

linear_to_gamma :: proc(linear_component: f64) -> f64 {
	return linalg.sqrt(linear_component)
}
