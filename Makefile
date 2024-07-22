default:
	odin run . -debug -out:.build/main

prod:
	odin run . -out:.build/main
