package main

import "core:fmt"
import "core:math/linalg"
import "core:strings"


Color :: Vec3

write_color :: proc(sb: ^strings.Builder, pixel_color: Color, samples_per_pixel: int) {
	r := pixel_color.r
	g := pixel_color.g
	b := pixel_color.b

	// Divide the color by the number of samples.
	scale := 1.0 / f64(samples_per_pixel)
	r *= scale
	g *= scale
	b *= scale

	r = linear_to_gamma(r)
	g = linear_to_gamma(g)
	b = linear_to_gamma(b)

	// Write the translated [0,255] value of each color component.
	intensity := Interval{0.000, 0.999}
	out_r := int(256 * interval_clamp(intensity, r))
	out_g := int(256 * interval_clamp(intensity, g))
	out_b := int(256 * interval_clamp(intensity, b))

	fmt.sbprintf(sb, "%v %v %v\n", out_r, out_g, out_b)
}

linear_to_gamma :: proc(linear_component: f64) -> f64 {
	return linalg.sqrt(linear_component)
}
