package main


// Raytracing In One Weekend - Version 4.0.0-alpha.1, 2023-08-06
// https://raytracing.github.io/books/RayTracingInOneWeekend.html

main :: proc() {
	world := Hittable_List{}
	append(&world.objects, Sphere{{0, 0, -1}, 0.5})
	append(&world.objects, Sphere{{0, -100.5, -1}, 100})

	cam := Camera {
		aspect_ratio = 16.0 / 9.0,
		image_width  = 400,
	}

	camera_render(cam, world)
}
