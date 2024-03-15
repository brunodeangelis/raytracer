package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/linalg/glsl"
import "core:os"
import "core:strings"

import stbi "vendor:stb/image"

INFINITY :: math.INF_F64
PI :: math.PI

Vec3 :: linalg.Vector3f64
Point3 :: Vec3
Color :: Vec3
Ray :: struct {
	orig: Point3,
	dir:  Vec3,
}

Hit_Record :: struct {
	p:          Point3,
	normal:     Vec3,
	t:          f64,
	front_face: bool,
}

Sphere :: struct {
	center: Point3,
	radius: f64,
}

Hittable_List :: struct {
	objects: [dynamic]Hittable,
}

Hittable :: union {
	Sphere,
	Hittable_List,
}

// Raytracing In One Weekend - Version 4.0.0-alpha.1, 2023-08-06
// https://raytracing.github.io/books/RayTracingInOneWeekend.html

main :: proc() {
	aspect_ratio := 16.0 / 9.0
	image_width := 400

	// Calculate the image height, and ensure that it's at least 1.
	image_height := int(f64(image_width) / aspect_ratio)
	image_height = (image_height < 1) ? 1 : image_height

	// World

	world := Hittable_List{}
	append(&world.objects, Sphere{{0, 0, -1}, 0.5})
	append(&world.objects, Sphere{{0, -100.5, -1}, 100})

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

			pixel_color := ray_color(r, world)
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

hit :: proc(h: Hittable, r: Ray, ray_t: Interval, rec: ^Hit_Record) -> bool {
	#partial switch type in h {
	case Sphere:
		h := h.(Sphere)

		oc := r.orig - h.center
		a := linalg.length2(r.dir) // same as dot(dir, dir)
		half_b := linalg.dot(oc, r.dir)
		c := linalg.length2(oc) - h.radius * h.radius

		discriminant := half_b * half_b - a * c
		if discriminant < 0 do return false
		sqrtd := linalg.sqrt(discriminant)

		// Find the nearest root that lies in the acceptable range.
		root := (-half_b - sqrtd) / a
		if !interval_surrounds(ray_t, root) {
			root = (-half_b + sqrtd) / a
			if !interval_surrounds(ray_t, root) do return false
		}

		rec.t = root
		rec.p = ray_at(r, rec.t)
		outward_normal := (rec.p - h.center) / h.radius
		set_face_normal(rec, r, outward_normal)

		return true

	case Hittable_List:
		h := h.(Hittable_List)

		temp_rec := Hit_Record{}
		hit_anything := false
		closest_so_far := ray_t.max

		for object in h.objects {
			if hit(object, r, {ray_t.min, closest_so_far}, &temp_rec) {
				hit_anything = true
				closest_so_far = temp_rec.t

				rec.p = temp_rec.p
				rec.normal = temp_rec.normal
				rec.front_face = temp_rec.front_face
				rec.t = temp_rec.t
			}
		}

		return hit_anything
	}

	return false
}

// Sets the hit record normal vector.
// NOTE: the parameter `outward_normal` is assumed to have unit length.
set_face_normal :: proc(rec: ^Hit_Record, r: Ray, outward_normal: Vec3) {
	rec.front_face = linalg.dot(r.dir, outward_normal) < 0
	rec.normal = rec.front_face ? outward_normal : -outward_normal
}

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
