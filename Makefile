install:
	mix deps.get
	cd apps/collected_live_web/assets/ && npm ci

dev:
	iex -S mix phx.server

status:
	gigalixir ps

logs:
	gigalixir logs

build_docker:
	docker run -it -v "$(shell pwd)":/tmp/app us.gcr.io/gigalixir-152404/herokuish:latest

deploy:
	git -c http.extraheader="GIGALIXIR-CLEAN: true" push gigalixir master
	make status
