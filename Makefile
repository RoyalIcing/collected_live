install:
	mix deps.get
	cd apps/collected_live_web/assets/ && npm ci

dev:
	iex -S mix phx.server

status:
	gigalixir ps

logs:
	gigalixir logs

build_docker_gigalixir:
	docker run -it -v "$(shell pwd)":/tmp/app us.gcr.io/gigalixir-152404/herokuish:latest

deploy_gigalixir:
	git -c http.extraheader="GIGALIXIR-CLEAN: true" push gigalixir master
	make status

deploy_app_engine:
	gcloud config set app/cloud_build_timeout 2000
	gcloud app deploy app.yaml --project "${PROJECT}"
