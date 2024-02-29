.PHONY: run
run: main
	LD_LIBRARY_PATH=. ./main

.PHONY: clean
clean:
	rm libA.so main

main: main.cpp libA.so
	g++ main.cpp -L. -lA -o main

libA.so: lib.cpp lib.h
	g++ lib.cpp -fPIC --shared -o libA.so