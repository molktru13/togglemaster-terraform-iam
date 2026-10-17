# ---- Build Stage ----
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copia os módulos e baixa as dependências (cache em camadas)
COPY go.mod go.sum ./
RUN go mod download

# Copia o código-fonte e compila o binário estático
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/auth-service .

# ---- Runtime Stage ----
FROM alpine:3.21

RUN apk upgrade --no-cache && apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/auth-service /app/auth-service

EXPOSE 8001

CMD ["/app/auth-service"]
