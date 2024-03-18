package main

import "core:fmt"
import "core:math/linalg"
import "core:strings"


Color :: Vec3

write_color :: proc(pixel_color: Color, buffer: []byte, x, y, width, samples_per_pixel: int) {
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

	pixel_idx := (x + y * width) * 3
	buffer[pixel_idx + 0] = byte(out_r)
	buffer[pixel_idx + 1] = byte(out_g)
	buffer[pixel_idx + 2] = byte(out_b)
}

linear_to_gamma :: proc(linear_component: f64) -> f64 {
	return linalg.sqrt(linear_component)
}
