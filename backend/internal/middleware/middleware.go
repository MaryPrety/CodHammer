package middleware

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/dgrijalva/jwt-go"
	"github.com/go-redis/redis/v8"
	"backend/internal/config"
	"backend/internal/models"
)

type contextKey string

const ClaimsContextKey contextKey = "claims"

// JWT возвращает middleware для проверки JWT токена
func JWT(jwtKey []byte, redisClient *redis.Client) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, "Authorization header required", http.StatusUnauthorized)
				return
			}

			tokenString := strings.TrimPrefix(authHeader, "Bearer ")
			if tokenString == authHeader {
				http.Error(w, "Invalid token format", http.StatusUnauthorized)
				return
			}

			claims := &models.Claims{}
			token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
				return jwtKey, nil
			})

			if err != nil || !token.Valid {
				http.Error(w, "Invalid token", http.StatusUnauthorized)
				return
			}

			if redisClient != nil {
				redisCtx := context.Background()
				sessionKey := fmt.Sprintf("session:%d:%s", claims.UserID, tokenString)
				exists, err := redisClient.Exists(redisCtx, sessionKey).Result()
				if err != nil {
					log.Printf("Warning: Failed to check session in Redis: %v", err)
				} else if exists > 0 {
					redisClient.Expire(redisCtx, sessionKey, config.SessionTTL)
				}
			}

			requestCtx := context.WithValue(r.Context(), ClaimsContextKey, claims)
			next.ServeHTTP(w, r.WithContext(requestCtx))
		})
	}
}

// Admin возвращает middleware для проверки прав администратора
func Admin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := r.Context().Value(ClaimsContextKey).(*models.Claims)
		if !ok {
			log.Println("Admin middleware: claims not found")
			http.Error(w, "Forbidden", http.StatusForbidden)
			return
		}

		log.Printf("Admin check for user %s (Role: %s)", strconv.Itoa(claims.UserID), claims.Role)

		if claims.Role != "admin" {
			log.Printf("Access denied for user %s", strconv.Itoa(claims.UserID))
			http.Error(w, "Forbidden", http.StatusForbidden)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// UTF8 устанавливает Content-Type с charset utf-8
func UTF8(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		next.ServeHTTP(w, r)
	})
}

// CORS устанавливает заголовки CORS
func CORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
		w.Header().Set("Access-Control-Expose-Headers", "Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
