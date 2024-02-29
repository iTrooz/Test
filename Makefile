.PHONY: run
run: main
	LD_LIBRARY_PATH=. ./main

main: main.c libA.so
	gcc main.c -L. -lA -o main

libA.so: lib.c lib.h
	gcc lib.c --shared -o libA.so