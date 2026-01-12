
chip-8din: $(wildcard *.odin)
	odin build src -o:size -out:chip-8din

debug: $(wildcard *.odin)
	odin build src -debug -o:size -out:chip-8din

clean:
	rm chip-8din
