package main

import "core:fmt"
import "core:math/linalg"
import "core:math/linalg/glsl"
import "core:os"
import "core:strings"

import stbi "vendor:stb/image"

Vec3 :: linalg.Vector3f64
Point3 :: Vec3
Color :: Vec3
Ray :: struct {
	orig: Point3,
	dir:  Vec3,
}

// Raytracing In One Weekend - Version 4.0.0-alpha.1, 2023-08-06
// https://raytracing.github.io/books/RayTracingInOneWeekend.html

main :: proc() {
	aspect_ratio := 16.0 / 9.0
	image_width := 400

	// Calculate the image height, and ensure that it's at least 1.
	image_height := int(f64(image_width) / aspect_ratio)
	image_height = (image_height < 1) ? 1 : image_height

	// Camera

	focal_length := 1.0
	viewport_height := 2.0
	viewport_width := viewport_height * (f64(image_width) / f64(image_height))
	camera_center := Point3{0, 0, 0}

	// Calculate the vectors across the horizontal and down the vertical viewport edges.
	// https://raytracing.github.io/images/fig-1.04-pixel-grid.jpg
	viewport_u := Vec3{viewport_width, 0, 0}
	viewport_v := Vec3{0, -viewport_height, 0}

	// Calculate the horizontal and vertical delta vectors from pixel to pixel.
	pixel_delta_u := viewport_u / f64(image_width)
	pixel_delta_v := viewport_v / f64(image_height)

	// Calculate the location of the upper left pixel.
	viewport_upper_left := camera_center - Vec3{0, 0, focal_length} - viewport_u / 2 - viewport_v / 2
	pixel00_loc := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

	sb := strings.builder_make_none()
	fmt.sbprintf(&sb, "P3\n%v %v\n255\n", image_width, image_height)

	for j in 0 ..< image_height {
		fmt.printf("\rScanlines remaining: %v", image_height - j)
		for i in 0 ..< image_width {
			pixel_center := pixel00_loc + (f64(i) * pixel_delta_u) + (f64(j) * pixel_delta_v)
			ray_direction := pixel_center - camera_center
			r := Ray {
				orig = camera_center,
				dir  = ray_direction,
			}

			pixel_color := ray_color(r)
			write_color(&sb, pixel_color)
		}
	}

	os.write_entire_file("image.ppm", sb.buf[:])

	fmt.printf("\rDone.                    \n")
}

write_color :: proc(sb: ^strings.Builder, px_color: Color) {
	ir := i32(255 * px_color.r)
	ig := i32(255 * px_color.g)
	ib := i32(255 * px_color.b)
	fmt.sbprintf(sb, "%v %v %v\n", ir, ig, ib)
}

ray_at :: proc(r: Ray, t: f64) -> Point3 {
	return r.orig + t * r.dir
}

hit_sphere :: proc(center: Point3, radius: f64, r: Ray) -> bool {
	oc := r.orig - center
	a := linalg.dot(r.dir, r.dir)
	b := 2.0 * linalg.dot(oc, r.dir)
	c := linalg.dot(oc, oc) - radius * radius
	discriminant := b * b - 4 * a * c
	return discriminant >= 0
}

ray_color :: proc(r: Ray) -> Color {
	if hit_sphere({0, 0, -1}, 0.5, r) {
		return {1, 0, 0}
	}

	// unit_vector() is equal to normalize()
	unit_direction := linalg.vector_normalize(r.dir)
	blue := Color{0.5, 0.7, 1.0}
	white := Color{1.0, 1.0, 1.0}
	t := 0.5 * (unit_direction.y + 1.0)
	return linalg.lerp(white, blue, t)
}
