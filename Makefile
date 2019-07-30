install:
	mix deps.get
	cd apps/collected_live_web/assets/ && npm ci

dev:
	iex -S mix phx.server

deploy:
	git push gigalixir master
