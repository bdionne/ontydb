all: deps compile

compile:
	@./rebar compile

deps:
	@./rebar get-deps

clean:
	@./rebar clean

test: compile
	./rebar eunit skip_deps=true

distclean: clean
	@./rebar delete-deps
	@rm -Rf deps
	@rm -Rf ebin

trigrams: src/354984si.ngl.gz ebin/indexer_trigrams.beam
	@erl -pa ebin -noshell -s indexer_trigrams make_tables\
                                        -s init stop



