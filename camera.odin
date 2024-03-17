package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:strings"


Camera :: struct {
	aspect_ratio:      f64, // Ratio of image width over height
	image_width:       int, // Rendered image width in pixel count
	samples_per_pixel: int, // Count of random samples for each pixel
	max_depth:         int, // Maximum number of ray bounces into scene
	vfov:              f64, // Vertical Field of View
	look_from:         Point3, // Point camera is looking from
	look_at:           Point3, // Point camera is looking at
	vup:               Vec3, // Camera-relative "up" direction
}

@(private = "file")
image_height: int // Rendered image height

@(private = "file")
center: Point3 // Camera center

@(private = "file")
pixel00_loc: Point3 // Location of pixel 0,0

@(private = "file")
pixel_delta_u: Vec3 // Offset to pixel to the right

@(private = "file")
pixel_delta_v: Vec3 // Offset to pixel below

@(private = "file")
u, v, w: Vec3 // Camera frame basis vectors

camera_render :: proc(cam: Camera, world: Hittable) {
	initialize(cam)

	sb := strings.builder_make_none()
	fmt.sbprintf(&sb, "P3\n%v %v\n255\n", cam.image_width, image_height)

	for j in 0 ..< image_height {
		fmt.printf("\rScanlines remaining: %v ", image_height - j)
		for i in 0 ..< cam.image_width {
			pixel_color := Color{}
			for sample in 0 ..< cam.samples_per_pixel {
				r := get_ray(i, j)
				pixel_color += ray_color(r, cam.max_depth, world)
			}

			write_color(&sb, pixel_color, cam.samples_per_pixel)
		}
	}

	os.write_entire_file("render.ppm", sb.buf[:])

	fmt.printf("\rDone.                    \n")
}

@(private = "file")
initialize :: proc(cam: Camera) {
	image_height = int(f64(cam.image_width) / cam.aspect_ratio)
	image_height = (image_height < 1) ? 1 : image_height

	// Determine viewport dimensions.
	focal_length := linalg.length(cam.look_from - cam.look_at)
	theta := linalg.to_radians(cam.vfov)
	h := linalg.tan(theta / 2)
	viewport_height := 2 * h * focal_length
	viewport_width := viewport_height * (f64(cam.image_width) / f64(image_height))

	// Calculate the u,v,w unit basis vectors for the camera coordinate frame.
	w := linalg.normalize(cam.look_from - cam.look_at)
	u := linalg.normalize(linalg.cross(cam.vup, w))
	v := linalg.cross(w, u)

	// Calculate the vectors across the horizontal and down the vertical viewport edges.
	// https://raytracing.github.io/images/fig-1.04-pixel-grid.jpg
	viewport_u := viewport_width * u // Vector across viewport horizontal edge
	viewport_v := viewport_height * -v // Vector down viewport vertical edge

	// Calculate the horizontal and vertical delta vectors from pixel to pixel.
	pixel_delta_u = viewport_u / f64(cam.image_width)
	pixel_delta_v = viewport_v / f64(image_height)

	// Calculate the location of the upper left pixel.
	center = cam.look_from
	viewport_upper_left := center - (focal_length * w) - viewport_u / 2 - viewport_v / 2
	pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)
}

@(private = "file")
get_ray :: proc(i, j: int) -> Ray {
	// Get a randomly sampled camera ray for the pixel at location i,j.
	pixel_center := pixel00_loc + (f64(i) * pixel_delta_u) + (f64(j) * pixel_delta_v)
	pixel_sample := pixel_center + pixel_sample_square()

	ray_origin := center
	ray_direction := pixel_sample - ray_origin

	return Ray{ray_origin, ray_direction}
}

@(private = "file")
pixel_sample_square :: proc() -> Vec3 {
	// Returns a random point in the square surrounding a pixel at the origin.
	px := -0.5 + rand.float64()
	py := -0.5 + rand.float64()
	return (px * pixel_delta_u) + (py * pixel_delta_v)
}

@(private = "file")
ray_color :: proc(r: Ray, depth: int, world: Hittable) -> Color {
	rec := Hit_Record{}

	// If we've exceeded the ray bounce limit, no more light is gathered.
	if depth <= 0 do return {0, 0, 0}

	if hit(world, r, {0.001, INFINITY}, &rec) {
		scattered: Ray
		attenuation: Color
		if material_scatter(rec.mat, r, rec, &attenuation, &scattered) {
			return attenuation * ray_color(scattered, depth - 1, world)
		}
		return Color{0, 0, 0}
	}

	// unit_vector() is equal to normalize()
	unit_direction := linalg.normalize(r.dir)
	blue := Color{0.5, 0.7, 1.0}
	white := Color{1.0, 1.0, 1.0}
	lerp_t := 0.5 * (unit_direction.y + 1.0)
	return linalg.lerp(white, blue, lerp_t)
}
