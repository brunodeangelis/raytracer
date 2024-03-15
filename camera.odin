package main

import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:strings"


Camera :: struct {
	aspect_ratio: f64,
	image_width:  f64,
}

@(private = "file")
image_height: int

@(private = "file")
center: Point3

@(private = "file")
pixel00_loc: Point3

@(private = "file")
pixel_delta_u: Vec3

@(private = "file")
pixel_delta_v: Vec3

camera_render :: proc(cam: Camera, world: Hittable) {
	initialize(cam)

	sb := strings.builder_make_none()
	fmt.sbprintf(&sb, "P3\n%v %v\n255\n", cam.image_width, image_height)

	for j in 0 ..< image_height {
		fmt.printf("\rScanlines remaining: %v", image_height - j)
		for i in 0 ..< cam.image_width {
			pixel_center := pixel00_loc + (f64(i) * pixel_delta_u) + (f64(j) * pixel_delta_v)
			ray_direction := pixel_center - center
			r := Ray {
				orig = center,
				dir  = ray_direction,
			}

			pixel_color := ray_color(r, world)
			write_color(&sb, pixel_color)
		}
	}

	os.write_entire_file("image.ppm", sb.buf[:])

	fmt.printf("\rDone.                    \n")
}

@(private = "file")
initialize :: proc(cam: Camera) {
	image_height = int(f64(cam.image_width) / cam.aspect_ratio)
	image_height = (image_height < 1) ? 1 : image_height

	// Determine viewport dimensions.
	focal_length := 1.0
	viewport_height := 2.0
	viewport_width := viewport_height * (f64(cam.image_width) / f64(image_height))

	// Calculate the vectors across the horizontal and down the vertical viewport edges.
	// https://raytracing.github.io/images/fig-1.04-pixel-grid.jpg
	viewport_u := Vec3{viewport_width, 0, 0}
	viewport_v := Vec3{0, -viewport_height, 0}

	// Calculate the horizontal and vertical delta vectors from pixel to pixel.
	pixel_delta_u = viewport_u / f64(cam.image_width)
	pixel_delta_v = viewport_v / f64(image_height)

	// Calculate the location of the upper left pixel.
	center = {0, 0, 0}
	viewport_upper_left := center - {0, 0, focal_length} - viewport_u / 2 - viewport_v / 2
	pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)
}

@(private = "file")
ray_color :: proc(r: Ray, world: Hittable) -> Color {
	rec := Hit_Record{}
	if hit(world, r, {0, INFINITY}, &rec) {
		return 0.5 * (rec.normal + {1, 1, 1})
	}

	// unit_vector() is equal to normalize()
	unit_direction := linalg.vector_normalize(r.dir)
	blue := Color{0.5, 0.7, 1.0}
	white := Color{1.0, 1.0, 1.0}
	lerp_t := 0.5 * (unit_direction.y + 1.0)
	return linalg.lerp(white, blue, lerp_t)
}
