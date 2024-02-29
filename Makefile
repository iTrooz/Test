.PHONY: run
run: main.exe
	LD_LIBRARY_PATH=. ./main.exe

.PHONY: clean
clean:
	rm libA.dll main.exe

main.exe: main.cpp libA.dll
	g++ main.cpp -L. -lA -o main.exe

libA.dll: lib.cpp lib.h
	g++ lib.cpp -fPIC --shared -o libA.dll