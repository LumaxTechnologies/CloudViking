# 🐳 Docker Development Best Practices

A concise reference for developers working with Docker containers and Docker Compose.

---

## 🧑‍💻 Connect to a Running Container with Bash

```bash
docker exec -it <container_name_or_id> bash
```

**Tip:** Use `sh` instead of `bash` for minimal containers (e.g. Alpine).

---

## 🏷️ Name Containers for Easy Access

In `docker run`:

```bash
docker run --name myapp -d myimage
```

In `docker-compose.yml`:

```yaml
services:
  app:
    container_name: myapp
```

---

## ▶️ Start / ⏹️ Stop Docker Compose Stacks

```bash
# Start in foreground (logs shown)
docker compose up

# Start in detached mode
docker compose up -d

# Stop containers
docker compose stop

# Stop and remove containers, networks, etc.
docker compose down
```

---

## 🔨 Build, Tag, and Flash Docker Images

### Build with a custom tag

```bash
docker build -t myimage:latest .
```

### Tag an existing image

```bash
docker tag myimage myrepo/myimage:1.0.0
```

### Create an image from a running container

```bash
docker commit <container_id> myimage:snapshot
```

---

## 🌐 Expose Ports

In `docker run`:

```bash
docker run -p 8080:80 myimage
```

In `docker-compose.yml`:

```yaml
ports:
  - "8080:80"
```

> Format: `host_port:container_port`

---

## 📂 Mount Local Folders

In `docker run`:

```bash
docker run -v $(pwd)/data:/app/data myimage
```

In `docker-compose.yml`:

```yaml
volumes:
  - ./data:/app/data
```

---

## 👤 Manage the Running User

### In Dockerfile

```Dockerfile
USER appuser
```

### At runtime

```bash
docker run -u $(id -u):$(id -g) myimage
```

In `docker-compose.yml`:

```yaml
user: "${UID}:${GID}"
```

> Useful for ensuring correct file permissions between host and container.

---

## 📦 Manage Volumes

### Create a named volume

```bash
docker volume create myvolume
```

### Mount it

```bash
docker run -v myvolume:/data myimage
```

In Compose:

```yaml
volumes:
  - myvolume:/data
```

Define it:

```yaml
volumes:
  myvolume:
```

---

## 🧹 Clear Specific or All Containers

### Remove specific container

```bash
docker rm -f <container_id_or_name>
```

### Remove all containers

```bash
docker rm -f $(docker ps -aq)
```

---

## 🧼 Clear Specific or All Volumes

### Remove specific volume

```bash
docker volume rm myvolume
```

### Remove all unused volumes

```bash
docker volume prune
```

### Remove all volumes

```bash
docker volume rm $(docker volume ls -q)
```

---

## 🧭 General Tips

* Use `.dockerignore` to speed up builds and reduce image size.
* Use `ENTRYPOINT` for app binaries, and `CMD` for default args.
* Avoid running as root unless necessary.
* Keep images small (multi-stage builds, Alpine base if possible).
* Use named volumes for data persistence between container restarts.
