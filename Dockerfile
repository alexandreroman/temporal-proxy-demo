# syntax=docker/dockerfile:1

# One image, three binaries: the Worker, the API and the KMS server are always
# the same build, and each Deployment picks the binary it runs with its own
# `command`.
FROM golang:1.27-alpine AS build
WORKDIR /src

# Dependencies first, so editing a source file does not refetch the modules.
COPY go.mod go.sum ./
RUN --mount=type=cache,id=gomod,target=/go/pkg/mod \
    go mod download

COPY . .
# CGO_ENABLED=0 makes all three binaries static, which is what lets the
# runtime stage be a distroless image with no libc at all.
RUN --mount=type=cache,id=gomod,target=/go/pkg/mod \
    --mount=type=cache,id=gobuild,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /app/ ./cmd/worker ./cmd/app ./cmd/kms

# The :nonroot tag already runs as USER 65532:65532.
FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /app/worker /app/app /app/kms /app/
# No default command on purpose: an image carrying several binaries has no
# single one to prefer, so every Deployment names the binary it wants.
