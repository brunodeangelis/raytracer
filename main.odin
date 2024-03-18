package main

import "core:math/linalg"
import "core:math/rand"

// Raytracing In One Weekend - Version 4.0.0-alpha.1, 2023-08-06
// https://raytracing.github.io/books/RayTracingInOneWeekend.html

main :: proc() {
	world := Hittable_List{}

	material_ground := Material {
		type   = .LAMBERTIAN,
		albedo = {0.5, 0.5, 0.5},
	}
	append(&world.objects, Sphere{{0, -1000, 0}, 1000, &material_ground})

	for a in -11 ..< 11 {
		for b in -11 ..< 11 {
			choose_mat := rand.float64()
			center := Point3{f64(a) + 0.9 * rand.float64(), 0.2, f64(b) + 0.9 * rand.float64()}

			if linalg.length(center - {4, 0.2, 0}) > 0.9 {
				sphere_material: Material

				if choose_mat < 0.75 {
					// diffuse
					sphere_material = Material {
						type   = .LAMBERTIAN,
						albedo = cast(Color)(random_vec3() * random_vec3()),
					}
				} else if choose_mat < 0.9 {
					// metal
					sphere_material = Material {
						type   = .METAL,
						albedo = cast(Color)random_vec3(0.5, 1),
						fuzz   = rand.float64_range(0, 0.5),
					}
				} else {
					// glass
					sphere_material = Material {
						type = .DIELECTRIC,
						ir   = 1.5,
					}
				}

				append(&world.objects, Sphere{center, 0.2, new_clone(sphere_material)})
			}
		}
	}

	material1 := Material {
		type = .DIELECTRIC,
		ir   = 1.5,
	}
	append(&world.objects, Sphere{{0, 1, 0}, 1, &material1})

	material2 := Material {
		type   = .LAMBERTIAN,
		albedo = {0.4, 0.2, 0.1},
	}
	append(&world.objects, Sphere{{-4, 1, 0}, 1, &material2})

	material3 := Material {
		type   = .METAL,
		albedo = {0.7, 0.6, 0.5},
		fuzz   = 0,
	}
	append(&world.objects, Sphere{{4, 1, 0}, 1, &material3})

	cam := Camera {
		aspect_ratio      = 16.0 / 9.0,
		image_width       = 1200,
		samples_per_pixel = 500,
		max_depth         = 50,
		vfov              = 20,
		look_from         = {13, 2, 3},
		look_at           = {0, 0, 0},
		vup               = {0, 1, 0},
		defocus_angle     = 0.6,
		focus_dist        = 10,
	}

	camera_render(cam, world)
}
