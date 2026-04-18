package session

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
	"backend/internal/config"
)

// SaveToRedis сохраняет сессию в Redis
func SaveToRedis(client *redis.Client, userID int, tokenString string, expirationTime time.Time) error {
	if client == nil {
		return fmt.Errorf("Redis client is not initialized")
	}

	ctx := context.Background()
	sessionKey := fmt.Sprintf("session:%d:%s", userID, tokenString)

	if err := client.Set(ctx, sessionKey, "1", config.SessionTTL).Err(); err != nil {
		return err
	}

	sessionsKey := fmt.Sprintf("user_sessions:%d", userID)
	if err := client.SAdd(ctx, sessionsKey, sessionKey).Err(); err != nil {
		return err
	}

	client.Expire(ctx, sessionsKey, config.SessionTTL)

	sessionCount, err := client.SCard(ctx, sessionsKey).Result()
	if err != nil {
		return err
	}

	if sessionCount > config.MaxSessionsPerUser {
		sessions, err := client.SMembers(ctx, sessionsKey).Result()
		if err != nil {
			return err
		}
		sessionsToRemove := len(sessions) - config.MaxSessionsPerUser
		for i := 0; i < sessionsToRemove; i++ {
			client.SRem(ctx, sessionsKey, sessions[i])
			client.Del(ctx, sessions[i])
		}
	}

	return nil
}
