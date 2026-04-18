package config

import (
	"fmt"
	"os"
	"time"

	"github.com/joho/godotenv"
)

const (
	MaxSessionsPerUser      = 5
	DefaultEventRetentionDays = 3
	SessionTTL              = 24 * time.Hour
)

// LoadEnv загружает переменные окружения из .env файла
func LoadEnv() {
	if err := godotenv.Load(); err != nil {
		// Игнорируем ошибку, если .env не найден
	}
}

// GetJWTKey возвращает JWT ключ из переменной окружения
func GetJWTKey() []byte {
	if key := os.Getenv("JWT_SECRET_KEY"); key != "" {
		fmt.Println("Using JWT key from environment variable")
		return []byte(key)
	}
	return nil
}

// GetPort возвращает порт для сервера
func GetPort() string {
	port := os.Getenv("PORT")
	if port == "" {
		return "8080"
	}
	return port
}

// GetServerAddress возвращает адрес сервера (ip:port)
func GetServerAddress() string {
	ip := os.Getenv("IP")
	if ip == "" {
		ip = "0.0.0.0"
	}
	return ip + ":" + GetPort()
}
