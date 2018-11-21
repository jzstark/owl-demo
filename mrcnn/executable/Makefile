
default: build

.PHONY: build clean
build:
	dune build examples/demo.exe
	cp _build/default/examples/demo.exe mrcnn_demo.exe

clean:
	dune clean
