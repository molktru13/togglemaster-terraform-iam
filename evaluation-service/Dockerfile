# ---- Build Stage ----
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copia os módulos e baixa as dependências (cache em camadas)
COPY go.mod go.sum ./
RUN go mod download

# Copia o código-fonte e compila o binário estático
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/evaluation-service .

# ---- Runtime Stage ----
FROM alpine:3.21

RUN apk upgrade --no-cache && apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/evaluation-service /app/evaluation-service

EXPOSE 8004

CMD ["/app/evaluation-service"]
