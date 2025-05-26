FROM golang:1.23.8-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .

FROM alpine:latest
RUN  apk --no-cache add ca-certificates tzdata 
WORKDIR /app
COPY --from=builder /app/main .
COPY .env .
EXPOSE 8080

CMD ["./main"]