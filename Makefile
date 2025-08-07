init:
	docker compose run api npm install

dev:
	docker compose up --remove-orphans --build

test:
	docker compose run api npm run test