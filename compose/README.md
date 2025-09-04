# Docker Compose
The provided compose file will start a basic single example Catena service.

## TL;DR
```
git clone git@github.com/Catena-deployments
cd Catena-deployments/compose
docker compose up -d
```

## Configuration
You can customize the compose file by setting the following variables by creating a `.env` file in the `compose` directory. Further customization can be done by editing the `compose.yaml` file directly.

| Variable | Description |
|----------|-------------|
| `TAG` | The image tag to use. See the [Catena README](../README.md#how-to-use-this-image) for more information. |
| `PORT` | The port to expose. |
