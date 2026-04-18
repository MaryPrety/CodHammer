package database

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

// InitDB инициализирует подключение к PostgreSQL и выполняет миграции
func InitDB() *sql.DB {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable client_encoding='UTF8'",
		host, port, user, password, dbname)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err = db.Ping(); err != nil {
		log.Fatal("Database ping failed:", err)
	}

	runMigrations(db)
	fmt.Println("Successfully connected to PostgreSQL")
	return db
}

// InitRedis инициализирует подключение к Redis
func InitRedis() *redis.Client {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "127.0.0.1:6379"
	}
	redisPassword := os.Getenv("REDIS_PASSWORD")

	redisOptions := &redis.Options{
		Addr: redisAddr,
		DB:   0,
	}
	if redisPassword != "" {
		redisOptions.Password = redisPassword
	}

	client := redis.NewClient(redisOptions)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := client.Ping(ctx).Result()
	if err != nil {
		if redisPassword != "" && strings.Contains(err.Error(), "AUTH") {
			log.Printf("Warning: Redis authentication failed. Trying to connect without password...")
			client = redis.NewClient(&redis.Options{Addr: redisAddr, DB: 0})
			_, err = client.Ping(ctx).Result()
			if err == nil {
				log.Printf("Successfully connected to Redis at %s (without password)\n", redisAddr)
				return client
			}
		}
		log.Printf("Warning: Failed to connect to Redis at %s: %v", redisAddr, err)
		log.Println("Redis connection failed. The application will continue, but session management will be disabled.")
		return nil
	}
	fmt.Printf("Successfully connected to Redis at %s\n", redisAddr)
	return client
}

func runMigrations(db *sql.DB) {
	migrations := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			first_name TEXT,
			last_name TEXT,
			username TEXT UNIQUE,
			study_group TEXT,
			enrollment_year INTEGER,
			educational_institution TEXT,
			email TEXT NOT NULL UNIQUE,
			password TEXT NOT NULL,
			role TEXT NOT NULL DEFAULT 'student',
			age INTEGER,
			status TEXT NOT NULL DEFAULT 'Active',
			phone TEXT,
			points INTEGER NOT NULL DEFAULT 0,
			created_at TIMESTAMP NOT NULL
		)`,
		`ALTER TABLE users ADD COLUMN IF NOT EXISTS educational_institution TEXT`,
		`ALTER TABLE users ADD COLUMN IF NOT EXISTS educational_direction TEXT`,
		`CREATE TABLE IF NOT EXISTS user_responses (
			id SERIAL PRIMARY KEY,
			user_id INTEGER REFERENCES users(id),
			survey_id INTEGER NOT NULL,
			answers JSONB NOT NULL,
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS events (
			id SERIAL PRIMARY KEY,
			title TEXT NOT NULL,
			description TEXT,
			type TEXT NOT NULL DEFAULT 'Conference',
			start_date TIMESTAMP NOT NULL,
			end_date TIMESTAMP NOT NULL,
			user_id INTEGER REFERENCES users(id),
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		)`,
		`ALTER TABLE events ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'Conference'`,
		`CREATE TABLE IF NOT EXISTS products (
			id SERIAL PRIMARY KEY,
			name TEXT NOT NULL,
			description TEXT,
			price NUMERIC NOT NULL,
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS surveys (
			id SERIAL PRIMARY KEY,
			title TEXT NOT NULL,
			description TEXT,
			questions JSONB NOT NULL,
			created_by INTEGER REFERENCES users(id),
			created_at TIMESTAMP NOT NULL DEFAULT NOW(),
			is_active BOOLEAN DEFAULT true,
			image_url TEXT,
			end_date TIMESTAMP
		)`,
		`ALTER TABLE surveys ADD COLUMN IF NOT EXISTS image_url TEXT`,
		`ALTER TABLE surveys ADD COLUMN IF NOT EXISTS end_date TIMESTAMP`,
		`CREATE TABLE IF NOT EXISTS survey_points (
			id SERIAL PRIMARY KEY,
			survey_id INTEGER NOT NULL,
			points INTEGER NOT NULL,
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS user_interests (
			user_id INTEGER PRIMARY KEY REFERENCES users(id),
			interests JSONB NOT NULL DEFAULT '[]'::jsonb
		)`,
		`CREATE TABLE IF NOT EXISTS user_stats (
			user_id INTEGER REFERENCES users(id),
			polls FLOAT DEFAULT 0,
			hackathons FLOAT DEFAULT 0,
			attendance FLOAT DEFAULT 0,
			conferences FLOAT DEFAULT 0,
			bet FLOAT DEFAULT 0
		)`,
		`ALTER TABLE user_stats ALTER COLUMN polls TYPE FLOAT USING polls::FLOAT`,
		`ALTER TABLE user_stats ALTER COLUMN hackathons TYPE FLOAT USING hackathons::FLOAT`,
		`ALTER TABLE user_stats ALTER COLUMN conferences TYPE FLOAT USING conferences::FLOAT`,
		`ALTER TABLE user_stats ALTER COLUMN bet TYPE FLOAT USING bet::FLOAT`,
		`CREATE TABLE IF NOT EXISTS weekly_activity (
			user_id INTEGER REFERENCES users(id),
			day TEXT NOT NULL,
			attendance INTEGER DEFAULT 0,
			hackathons INTEGER DEFAULT 0,
			polls INTEGER DEFAULT 0,
			PRIMARY KEY (user_id, day)
		)`,
	}

	for _, m := range migrations {
		if _, err := db.Exec(m); err != nil {
			log.Printf("Warning: Migration (may be already applied): %v", err)
		}
	}
}
