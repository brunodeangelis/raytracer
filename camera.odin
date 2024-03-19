package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:sync"


Camera :: struct {
	aspect_ratio:      f64, // Ratio of image width over height
	image_width:       int, // Rendered image width in pixel count
	samples_per_pixel: int, // Count of random samples for each pixel
	max_depth:         int, // Maximum number of ray bounces into scene
	vfov:              f64, // Vertical Field of View
	look_from:         Point3, // Point camera is looking from
	look_at:           Point3, // Point camera is looking at
	vup:               Vec3, // Camera-relative "up" direction
	defocus_angle:     f64, // Variation angle of rays through each pixel
	focus_dist:        f64, // Distance from camera look_from point to plane of perfect focus
}

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

@(private = "file")
defocus_disk_u: Vec3 // Defocus disk horizontal radius

@(private = "file")
defocus_disk_v: Vec3 // Defocus disk vertical radius

render :: proc(pixels: [^]byte, world: ^Hittable_List, cam: ^Camera) {
	for {
		current_pixel := sync.atomic_add(&pixel_index, 1)
		if current_pixel >= cam.image_width * image_height do return

		fmt.printf("\rPixels Remaining: %v", cam.image_width * image_height - current_pixel)

		x := current_pixel % cam.image_width
		y := current_pixel / cam.image_width

		pixel_color: Color
		for sample in 0 ..< cam.samples_per_pixel {
			r := get_ray(cam, x, y)
			pixel_color += ray_color(r, cam.max_depth, world^)
		}

		out_r, out_g, out_b := linear_to_byte(pixel_color / f64(cam.samples_per_pixel))
		pixel_idx := (x + y * cam.image_width) * 3
		pixels[pixel_idx + 0] = out_r
		pixels[pixel_idx + 1] = out_g
		pixels[pixel_idx + 2] = out_b
	}
}

camera_initialize :: proc(cam: Camera) {
	image_height = int(f64(cam.image_width) / cam.aspect_ratio)
	image_height = (image_height < 1) ? 1 : image_height

	// Determine viewport dimensions.
	theta := linalg.to_radians(cam.vfov)
	h := linalg.tan(theta / 2)
	viewport_height := 2 * h * cam.focus_dist
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
	viewport_upper_left := center - (cam.focus_dist * w) - viewport_u / 2 - viewport_v / 2
	pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

	// Calculate the camera defocus disk basis vectors.
	defocus_radius := cam.focus_dist * linalg.tan(linalg.to_radians(cam.defocus_angle / 2))
	defocus_disk_u = u * defocus_radius
	defocus_disk_v = v * defocus_radius
}

@(private = "file")
get_ray :: proc(cam: ^Camera, x, y: int) -> Ray {
	// Get a randomly sampled camera ray for the pixel at location x,y, originating from
	// the camera defocus disk.
	pixel_center := pixel00_loc + (f64(x) * pixel_delta_u) + (f64(y) * pixel_delta_v)
	pixel_sample := pixel_center + pixel_sample_square()

	ray_origin := (cam.defocus_angle <= 0) ? center : defocus_disk_sample()
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
defocus_disk_sample :: proc() -> Point3 {
	// Returns a random point in the camera defocus disk.
	p := random_vec3_in_unit_disk()
	return center + (p.x * defocus_disk_u) + (p.y * defocus_disk_v)
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
