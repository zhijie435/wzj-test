# wzj-test

Vue + Java sample web project with an H2 in-memory database.

## Project Layout

- `frontend/`: Vue 3 + Vite client
- `backend/`: Spring Boot REST API with Spring Data JPA and H2
- `scripts/`: reusable GitHub publication scripts

## Run Locally

Start the backend:

```bash
cd backend
mvn spring-boot:run
```

Start the frontend in another terminal:

```bash
cd frontend
npm install
npm run dev
```

Open `http://localhost:5173`. The Vite dev server proxies `/api` requests to
the Spring Boot server on `http://localhost:8080`.

## API

- `GET /api/tasks`: list sample tasks
- `POST /api/tasks`: create a task with `{ "title": "..." }`
- `PATCH /api/tasks/{id}/toggle`: toggle completion
- `DELETE /api/tasks/{id}`: delete a task

H2 console is available at `http://localhost:8080/h2-console` with:

- JDBC URL: `jdbc:h2:mem:wzjtest`
- User: `sa`
- Password: empty

## GitHub Scripts

Initial repository creation and push:

```bash
./scripts/01-bootstrap-and-publish.sh
```

Add a small extension commit and push it:

```bash
./scripts/02-add-files-commit.sh
```

Both scripts default to repository name `wzj-<current-directory-name>`. For this
folder the default is `wzj-test`. You can override it:

```bash
REPO_NAME=wzj-test ./scripts/01-bootstrap-and-publish.sh
REPO_NAME=wzj-test ./scripts/02-add-files-commit.sh
```
