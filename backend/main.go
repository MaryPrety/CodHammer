package main

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"net/smtp"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/go-redis/redis/v8"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

var db *sql.DB
var redisClient *redis.Client
var jwtKey []byte

const MaxSessionsPerUser = 5
const DefaultEventRetentionDays = 3 // Количество дней хранения завершённых событий
const SessionTTL = 24 * time.Hour    // Время жизни сессии в Redis

// User структура для хранения данных пользователя
type User struct {
	ID                     int    `json:"id"`
	FirstName              string `json:"first_name"`
	LastName               string `json:"last_name"`
	Username               string `json:"username"`
	Email                  string `json:"email"`
	Password               string `json:"password"`
	StudyGroup             string `json:"study_group"`
	EnrollmentYear         int    `json:"enrollment_year"`
	EducationalInstitution string `json:"educational_institution"`
	EducationalDirection   string `json:"educational_direction"`
	Semester               int    `json:"semester"`
	Course                 int    `json:"course"`
	Role                   string `json:"role"`
	Age                    int    `json:"age"`
	Phone                  string `json:"phone"`
	Points                 int    `json:"points"`
	Status                 string `json:"status"`
	CreatedAt              string `json:"created_at"`
}

// AuthResponse структура для ответа при авторизации
type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

// Claims структура для JWT
type Claims struct {
	UserID   int    `json:"id"`
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.StandardClaims
}

type Survey struct {
	ID          int        `json:"id"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Questions   []Question `json:"questions"`
	CreatedBy   int        `json:"created_by"`
	CreatedAt   time.Time  `json:"created_at"`
	IsActive    bool       `json:"is_active"`
	ImageURL    string     `json:"image_url,omitempty"`
	EndDate     *time.Time `json:"end_date,omitempty"`
}

// UnmarshalJSON кастомный парсинг для Survey, чтобы обрабатывать даты без часового пояса и многоязычные названия
func (s *Survey) UnmarshalJSON(data []byte) error {
	type Alias Survey
	aux := &struct {
		Title   interface{} `json:"title"`
		EndDate *string     `json:"end_date,omitempty"`
		*Alias
	}{
		Alias: (*Alias)(s),
	}

	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	// Обрабатываем title - может быть строкой или объектом с ru/en
	if aux.Title != nil {
		switch v := aux.Title.(type) {
		case string:
			s.Title = v
		case map[string]interface{}:
			// Если это объект, конвертируем в JSON строку для хранения в БД
			titleJSON, err := json.Marshal(v)
			if err != nil {
				return fmt.Errorf("cannot marshal title: %v", err)
			}
			s.Title = string(titleJSON)
		default:
			// Пытаемся преобразовать в строку
			s.Title = fmt.Sprintf("%v", v)
		}
	}

	// Парсим end_date, если она указана и не пустая
	if aux.EndDate != nil && *aux.EndDate != "" {
		endDateStr := *aux.EndDate
		// Если строка уже содержит часовой пояс (Z, +HH:MM, -HH:MM), парсим стандартным способом
		if strings.HasSuffix(endDateStr, "Z") || (len(endDateStr) > 6 && (strings.Contains(endDateStr[len(endDateStr)-6:], "+") || strings.Contains(endDateStr[len(endDateStr)-6:], "-"))) {
			t, err := time.Parse(time.RFC3339, endDateStr)
			if err != nil {
				return fmt.Errorf("cannot parse end_date: %v", err)
			}
			s.EndDate = &t
		} else {
			// Если нет часового пояса, парсим как UTC
			layouts := []string{
				"2006-01-02T15:04:05.000",
				"2006-01-02T15:04:05",
				"2006-01-02 15:04:05",
			}
			var parseErr error
			parsed := false
			for _, layout := range layouts {
				if t, err := time.ParseInLocation(layout, endDateStr, time.UTC); err == nil {
					s.EndDate = &t
					parsed = true
					break
				} else {
					parseErr = err
				}
			}
			if !parsed {
				return fmt.Errorf("cannot parse end_date: %s, error: %v", endDateStr, parseErr)
			}
		}
	} else {
		// Если end_date не указан или пустой, оставляем nil
		s.EndDate = nil
	}

	return nil
}

type Question struct {
	ID      int      `json:"id"`
	Text    string   `json:"text"`
	Type    string   `json:"type"`
	Options []string `json:"options,omitempty"`
}

// Структура для хранения ответов
type SurveyResponse struct {
	UserID    int       `json:"user_id"`
	SurveyID  int       `json:"survey_id"`
	Answers   []int     `json:"answers"`
	CreatedAt time.Time `json:"created_at"`
}

// Структура для хранения событий
type Event struct {
	ID          int       `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Type        string    `json:"type"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	UserID      int       `json:"user_id"`
	CreatedAt   time.Time `json:"created_at"`
}

// UnmarshalJSON кастомный парсинг для Event, чтобы обрабатывать даты без часового пояса
func (e *Event) UnmarshalJSON(data []byte) error {
	type Alias Event
	aux := &struct {
		StartDate string `json:"start_date"`
		EndDate   string `json:"end_date"`
		*Alias
	}{
		Alias: (*Alias)(e),
	}

	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	// Функция для парсинга даты с поддержкой форматов без часового пояса
	parseDateTime := func(dateStr string) (time.Time, error) {
		// Если строка уже содержит часовой пояс (Z, +HH:MM, -HH:MM), парсим стандартным способом
		if strings.HasSuffix(dateStr, "Z") || (len(dateStr) > 6 && (strings.Contains(dateStr[len(dateStr)-6:], "+") || strings.Contains(dateStr[len(dateStr)-6:], "-"))) {
			return time.Parse(time.RFC3339, dateStr)
		}

		// Если нет часового пояса, парсим как UTC
		layouts := []string{
			"2006-01-02T15:04:05.000",
			"2006-01-02T15:04:05",
			"2006-01-02 15:04:05",
		}
		for _, layout := range layouts {
			if t, err := time.ParseInLocation(layout, dateStr, time.UTC); err == nil {
				return t, nil
			}
		}

		return time.Time{}, fmt.Errorf("cannot parse date: %s", dateStr)
	}

	var err error
	e.StartDate, err = parseDateTime(aux.StartDate)
	if err != nil {
		return fmt.Errorf("cannot parse start_date: %v", err)
	}

	e.EndDate, err = parseDateTime(aux.EndDate)
	if err != nil {
		return fmt.Errorf("cannot parse end_date: %v", err)
	}

	return nil
}

// Структура для хранения товаров
type Product struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"created_at"`
}

func main() {
	// Инициализация JWT ключа
	initJWTKey()

	// Инициализация подключения к PostgreSQL
	initDB()
	defer db.Close()

	// Инициализация подключения к Redis
	initRedis()
	if redisClient != nil {
		defer redisClient.Close()
	}

	// Настройка маршрутов
	router := mux.NewRouter()
	router.Use(enableCORS)
	router.Use(utf8Middleware)

	// Маршруты регистрации и авторизации
	router.HandleFunc("/register", registerHandler).Methods("POST", "OPTIONS")
	router.HandleFunc("/login", loginHandler).Methods("POST", "OPTIONS")
	router.HandleFunc("/request-code", requestCodeHandler).Methods("POST", "OPTIONS")
	router.HandleFunc("/verify-code", verifyCodeHandler).Methods("POST", "OPTIONS")
	router.Handle("/logout", jwtMiddleware(http.HandlerFunc(logoutHandler))).Methods("POST", "OPTIONS")
	// Проверка работы базы данных
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprint(w, "DB connection error")
			return
		}
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	}).Methods("GET")

	// Маршруты пользователей/текущего пользователя
	router.Handle("/users", jwtMiddleware(http.HandlerFunc(getUsersHandler))).Methods("GET", "OPTIONS")
	router.Handle("/current-user", jwtMiddleware(http.HandlerFunc(getCurrentUserHandler))).Methods("GET", "OPTIONS")
	router.Handle("/profile", jwtMiddleware(http.HandlerFunc(getProfileHandler))).Methods("GET", "OPTIONS")
	router.Handle("/profile-update", jwtMiddleware(http.HandlerFunc(updateProfileHandler))).Methods("POST", "OPTIONS")

	// Маршруты получения/хранения опросника
	router.Handle("/surveys", jwtMiddleware(http.HandlerFunc(getSurveysHandler))).Methods("GET", "OPTIONS")
	router.Handle("/createsurvey", jwtMiddleware(adminMiddleware(http.HandlerFunc(createSurveyHandler)))).Methods("POST", "OPTIONS")
	router.Handle("/submitsurvey", jwtMiddleware(http.HandlerFunc(submitSurveyHandler))).Methods("POST", "OPTIONS")
	router.Handle("/surveys/{id}/statistics", jwtMiddleware(adminMiddleware(http.HandlerFunc(getSurveyStatisticsHandler)))).Methods("GET", "OPTIONS")

	// Маршруты управления событиями
	router.Handle("/events", jwtMiddleware(http.HandlerFunc(getEventsHandler))).Methods("GET", "OPTIONS")
	router.Handle("/createevent", jwtMiddleware(adminMiddleware(http.HandlerFunc(createEventHandler)))).Methods("POST", "OPTIONS")
	router.Handle("/events/{id}", jwtMiddleware(adminMiddleware(http.HandlerFunc(updateEventHandler)))).Methods("PUT", "OPTIONS")
	router.Handle("/events/{id}", jwtMiddleware(adminMiddleware(http.HandlerFunc(deleteEventHandler)))).Methods("DELETE", "OPTIONS")

	// Маршруты управления товарами
	router.Handle("/products", jwtMiddleware(http.HandlerFunc(getProductsHandler))).Methods("GET", "OPTIONS")
	router.Handle("/createproduct", jwtMiddleware(adminMiddleware(http.HandlerFunc(createProductHandler)))).Methods("POST", "OPTIONS")
	router.Handle("/products/{id}", jwtMiddleware(adminMiddleware(http.HandlerFunc(updateProductHandler)))).Methods("PUT", "OPTIONS")
	router.Handle("/products/{id}", jwtMiddleware(adminMiddleware(http.HandlerFunc(deleteProductHandler)))).Methods("DELETE", "OPTIONS")

	// Маршрут для добавления баллов за опросы
	router.Handle("/set-survey-points", jwtMiddleware(adminMiddleware(http.HandlerFunc(setSurveyPointsHandler)))).Methods("POST", "OPTIONS")

	// Запуск сервера
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	ip := os.Getenv("IP")
	if ip == "" {
		ip = "0.0.0.0"
	}
	serverAddress := ip + ":" + port
	fmt.Printf("Server is running"+" on %s\n", serverAddress)
	log.Fatal(http.ListenAndServe(":"+port, router))
}

// Инициализация JWT ключа
func initJWTKey() {
	if key := os.Getenv("JWT_SECRET_KEY"); key != "" {
		jwtKey = []byte(key)
		fmt.Println("Using JWT key from environment variable")
		return
	}
}

// Инициализация PostgreSQL
func initDB() {

	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	// Подключение к PostgreSQL
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable client_encoding='UTF8'",
		host, port, user, password, dbname)

	// Проверка подключения
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}

	// Добавить настройки пула соединений
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	err = db.Ping()
	if err != nil {
		log.Fatal("Database ping failed:", err)
	}

	//Таблица пользователей
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS users (
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
	);
	`
	_, err = db.Exec(createTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Добавляем колонку educational_institution, если её нет (для существующих таблиц)
	_, err = db.Exec(`ALTER TABLE users ADD COLUMN IF NOT EXISTS educational_institution TEXT`)
	if err != nil {
		log.Printf("Warning: Could not add educational_institution column (might already exist): %v", err)
	}

	// Добавляем колонку educational_direction, если её нет (для существующих таблиц)
	_, err = db.Exec(`ALTER TABLE users ADD COLUMN IF NOT EXISTS educational_direction TEXT`)
	if err != nil {
		log.Printf("Warning: Could not add educational_direction column (might already exist): %v", err)
	}

	// Таблица ответов
	createResponsesTableSQL := `
	CREATE TABLE IF NOT EXISTS user_responses (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
		survey_id INTEGER NOT NULL,
        answers JSONB NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );
	`

	_, err = db.Exec(createResponsesTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Таблица событий
	createEventsTableSQL := `
	CREATE TABLE IF NOT EXISTS events (
		id SERIAL PRIMARY KEY,
		title TEXT NOT NULL,
		description TEXT,
		type TEXT NOT NULL DEFAULT 'Conference',
		start_date TIMESTAMP NOT NULL,
		end_date TIMESTAMP NOT NULL,
		user_id INTEGER REFERENCES users(id),
		created_at TIMESTAMP NOT NULL DEFAULT NOW()
	);`

	_, err = db.Exec(createEventsTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Добавляем колонку type, если её нет (для существующих таблиц)
	_, err = db.Exec(`ALTER TABLE events ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'Conference'`)
	if err != nil {
		log.Printf("Warning: Could not add type column (might already exist): %v", err)
	}

	// Таблица товаров
	createProductTableSQL := `
	CREATE TABLE IF NOT EXISTS products (
		id SERIAL PRIMARY KEY,
		name TEXT NOT NULL,
		description TEXT,
		price NUMERIC NOT NULL,
		created_at TIMESTAMP NOT NULL DEFAULT NOW()
		);`

	_, err = db.Exec(createProductTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	createSurveysTableSQL := `
	CREATE TABLE IF NOT EXISTS surveys (
		id SERIAL PRIMARY KEY,
		title TEXT NOT NULL,
		description TEXT,
		questions JSONB NOT NULL,
		created_by INTEGER REFERENCES users(id),
		created_at TIMESTAMP NOT NULL DEFAULT NOW(),
		is_active BOOLEAN DEFAULT true,
		image_url TEXT,
		end_date TIMESTAMP
	);`

	_, err = db.Exec(createSurveysTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Добавляем колонки image_url и end_date, если их нет
	_, err = db.Exec(`ALTER TABLE surveys ADD COLUMN IF NOT EXISTS image_url TEXT`)
	if err != nil {
		log.Printf("Warning: Could not add image_url column (might already exist): %v", err)
	}
	_, err = db.Exec(`ALTER TABLE surveys ADD COLUMN IF NOT EXISTS end_date TIMESTAMP`)
	if err != nil {
		log.Printf("Warning: Could not add end_date column (might already exist): %v", err)
	}

	// Таблица для хранения баллов
	createSurveyPointsTableSQL := `
	CREATE TABLE IF NOT EXISTS survey_points (
		id SERIAL PRIMARY KEY,
		survey_id INTEGER NOT NULL,
		points INTEGER NOT NULL,
		created_at TIMESTAMP NOT NULL DEFAULT NOW()
	);`

	_, err = db.Exec(createSurveyPointsTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Таблица для хранения интересов пользователей
	createUserInterestsTableSQL := `
	CREATE TABLE IF NOT EXISTS user_interests (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    interests JSONB NOT NULL DEFAULT '[]'::jsonb
	);`

	_, err = db.Exec(createUserInterestsTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Таблица для хранения статистики пользователей
	createUserStatsTableSQL := `
	CREATE TABLE IF NOT EXISTS user_stats (
		user_id INTEGER REFERENCES users(id),
		polls FLOAT DEFAULT 0,
		hackathons FLOAT DEFAULT 0,
		attendance FLOAT DEFAULT 0,
		conferences FLOAT DEFAULT 0,
		bet FLOAT DEFAULT 0
	);
	`

	_, err = db.Exec(createUserStatsTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Миграция: изменяем типы колонок на FLOAT для существующих таблиц
	_, err = db.Exec(`ALTER TABLE user_stats ALTER COLUMN polls TYPE FLOAT USING polls::FLOAT`)
	if err != nil {
		log.Printf("Warning: Could not alter polls column (might already be FLOAT): %v", err)
	}
	_, err = db.Exec(`ALTER TABLE user_stats ALTER COLUMN hackathons TYPE FLOAT USING hackathons::FLOAT`)
	if err != nil {
		log.Printf("Warning: Could not alter hackathons column (might already be FLOAT): %v", err)
	}
	_, err = db.Exec(`ALTER TABLE user_stats ALTER COLUMN conferences TYPE FLOAT USING conferences::FLOAT`)
	if err != nil {
		log.Printf("Warning: Could not alter conferences column (might already be FLOAT): %v", err)
	}
	_, err = db.Exec(`ALTER TABLE user_stats ALTER COLUMN bet TYPE FLOAT USING bet::FLOAT`)
	if err != nil {
		log.Printf("Warning: Could not alter bet column (might already be FLOAT): %v", err)
	}

	// Таблица для хранения недельной активности пользователей
	createWeeklyActivityTableSQL := `
	CREATE TABLE IF NOT EXISTS weekly_activity (
		user_id INTEGER REFERENCES users(id),
		day TEXT NOT NULL,
		attendance INTEGER DEFAULT 0,
		hackathons INTEGER DEFAULT 0,
		polls INTEGER DEFAULT 0,
		PRIMARY KEY (user_id, day)
	);
	`

	_, err = db.Exec(createWeeklyActivityTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Successfully connected to PostgreSQL")
}

// Инициализация Redis
func initRedis() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		// Используем IPv4 адрес по умолчанию для локальной разработки
		redisAddr = "127.0.0.1:6379"
	}

	redisPassword := os.Getenv("REDIS_PASSWORD")
	// Если пароль не установлен в переменных окружения, используем пустую строку (без пароля)
	
	redisOptions := &redis.Options{
		Addr: redisAddr,
		DB:   0,
	}
	
	// Устанавливаем пароль только если он указан
	if redisPassword != "" {
		redisOptions.Password = redisPassword
	}

	redisClient = redis.NewClient(redisOptions)

	// Проверка подключения
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := redisClient.Ping(ctx).Result()
	if err != nil {
		// Если ошибка связана с аутентификацией и пароль был указан, пробуем без пароля
		if redisPassword != "" && strings.Contains(err.Error(), "AUTH") {
			log.Printf("Warning: Redis authentication failed. Trying to connect without password...")
			redisOptions := &redis.Options{
				Addr: redisAddr,
				DB:   0,
			}
			redisClient = redis.NewClient(redisOptions)
			
			// Пробуем подключиться без пароля
			_, err = redisClient.Ping(ctx).Result()
			if err == nil {
				log.Printf("Successfully connected to Redis at %s (without password)\n", redisAddr)
				return
			}
		}
		
		log.Printf("Warning: Failed to connect to Redis at %s: %v", redisAddr, err)
		log.Println("Redis connection failed. The application will continue, but session management will be disabled.")
		log.Println("To fix this, ensure Redis is running:")
		log.Printf("  - If using Docker: docker-compose up -d redis")
		if redisPassword != "" {
			log.Printf("  - If running locally: redis-server --requirepass %s", redisPassword)
		} else {
			log.Println("  - If running locally: redis-server (without password)")
		}
		// Не прерываем выполнение, но устанавливаем redisClient в nil
		// Это позволит приложению работать без Redis (с fallback)
		redisClient = nil
		return
	}

	fmt.Printf("Successfully connected to Redis at %s\n", redisAddr)
}

// Сохранение сессии в Redis
func saveSessionToRedis(userID int, tokenString string, expirationTime time.Time) error {
	if redisClient == nil {
		return fmt.Errorf("Redis client is not initialized")
	}
	
	ctx := context.Background()

	// Ключ сессии: session:userID:token
	sessionKey := fmt.Sprintf("session:%d:%s", userID, tokenString)

	// Сохраняем сессию с TTL
	err := redisClient.Set(ctx, sessionKey, "1", SessionTTL).Err()
	if err != nil {
		return err
	}

	// Управление количеством сессий пользователя
	// Получаем список всех сессий пользователя
	sessionsKey := fmt.Sprintf("user_sessions:%d", userID)
	err = redisClient.SAdd(ctx, sessionsKey, sessionKey).Err()
	if err != nil {
		return err
	}

	// Устанавливаем TTL для списка сессий
	redisClient.Expire(ctx, sessionsKey, SessionTTL)

	// Проверяем количество сессий
	sessionCount, err := redisClient.SCard(ctx, sessionsKey).Result()
	if err != nil {
		return err
	}

	// Если превышен лимит, удаляем самые старые сессии
	if sessionCount > MaxSessionsPerUser {
		// Получаем все сессии
		sessions, err := redisClient.SMembers(ctx, sessionsKey).Result()
		if err != nil {
			return err
		}

		// Удаляем лишние сессии (оставляем только последние MaxSessionsPerUser)
		sessionsToRemove := len(sessions) - MaxSessionsPerUser
		for i := 0; i < sessionsToRemove; i++ {
			// Удаляем первую сессию из списка
			redisClient.SRem(ctx, sessionsKey, sessions[i])
			redisClient.Del(ctx, sessions[i])
		}
	}

	return nil
}

// Блок: Регистрация и авторизация/Присвоение JWT-токена
// Функция Регистрации
func registerHandler(w http.ResponseWriter, r *http.Request) {
	var user struct {
		Username               string `json:"username"`
		Email                  string `json:"email"`
		Password               string `json:"password"`
		FirstName              string `json:"first_name"`
		LastName               string `json:"last_name"`
		StudyGroup             string `json:"study_group"`
		EnrollmentYear         int    `json:"enrollment_year"`
		EducationalInstitution string `json:"educational_institution"`
		EducationalDirection   string `json:"educational_direction"`
		Age                    int    `json:"age"`
		Phone                  string `json:"phone"`
	}

	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверка обязательных полей
	if user.Email == "" || user.Password == "" {
		http.Error(w, "Email and password are required", http.StatusBadRequest)
		return
	}
	if user.FirstName == "" {
		http.Error(w, "First name is required", http.StatusBadRequest)
		return
	}
	if user.LastName == "" {
		http.Error(w, "Last name is required", http.StatusBadRequest)
		return
	}
	if user.StudyGroup == "" {
		http.Error(w, "Study group is required", http.StatusBadRequest)
		return
	}
	if user.EnrollmentYear == 0 {
		http.Error(w, "Enrollment year is required", http.StatusBadRequest)
		return
	}
	if user.EducationalInstitution == "" {
		http.Error(w, "Educational institution is required", http.StatusBadRequest)
		return
	}
	if user.Age == 0 {
		http.Error(w, "Age is required", http.StatusBadRequest)
		return
	}
	if user.Phone == "" {
		http.Error(w, "Phone is required", http.StatusBadRequest)
		return
	}

	// Хеширование пароля
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	createdAt := time.Now().Format(time.RFC3339)

	// Вставка пользователя в базу данных
	var userID int
	var points int
	err = db.QueryRow(
		`INSERT INTO users (username, email, password, first_name, last_name, study_group, enrollment_year, educational_institution, educational_direction, age, phone, created_at) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
		 RETURNING id, points`,
		user.Username, user.Email, string(hashedPassword), user.FirstName, user.LastName,
		user.StudyGroup, user.EnrollmentYear, user.EducationalInstitution, user.EducationalDirection, user.Age, user.Phone, createdAt,
	).Scan(&userID, &points)

	if err != nil {
		// Проверка на дубликат
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
			if strings.Contains(err.Error(), "users_username_key") {
				http.Error(w, "Username already exists", http.StatusConflict)
				return
			}
			if strings.Contains(err.Error(), "users_email_key") {
				http.Error(w, "Email already exists", http.StatusConflict)
				return
			}
			if strings.Contains(err.Error(), "users_phone_key") {
				http.Error(w, "Phone already exists", http.StatusConflict)
				return
			}
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"id":          userID,
		"username":    user.Username,
		"email":       user.Email,
		"first_name":  user.FirstName,
		"last_name":   user.LastName,
		"study_group": user.StudyGroup,
		"points":      points,
		"message":     "User registered successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Функция авторизации
func loginHandler(w http.ResponseWriter, r *http.Request) {
	var creds struct {
		EmailOrPhone string `json:"emailOrPhone"`
		Password     string `json:"password"`
		SaveSession  bool   `json:"saveSession"`
	}

	err := json.NewDecoder(r.Body).Decode(&creds)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Поиск пользователя в базе данных
	var user User
	err = db.QueryRow(
		`SELECT id, username, email, password, role, age, phone, first_name, last_name, 
		 study_group, enrollment_year, points, created_at 
		 FROM users WHERE phone = $1 OR email = $1`,
		creds.EmailOrPhone,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Password, &user.Role, &user.Age,
		&user.Phone, &user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear,
		&user.Points, &user.CreatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusUnauthorized)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Проверка пароля
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(creds.Password))
	if err != nil {
		http.Error(w, "Invalid password", http.StatusUnauthorized)
		return
	}

	// ЗАКОММЕНТИРОВАНО: Отправка кода на email (можно вернуть, раскомментировав)
	/*
	// Генерируем код
	code, err := generateCode()
	if err != nil {
		http.Error(w, "Failed to generate code", http.StatusInternalServerError)
		return
	}

	// Сохраняем код в Redis с TTL 10 минут
	if redisClient != nil {
		ctx := context.Background()
		codeKey := fmt.Sprintf("auth_code:%s", user.Email)
		err = redisClient.Set(ctx, codeKey, code, 10*time.Minute).Err()
		if err != nil {
			log.Printf("Failed to save code to Redis: %v", err)
			http.Error(w, "Failed to save code", http.StatusInternalServerError)
			return
		}

		// Сохраняем информацию о saveSession для последующего использования
		sessionInfoKey := fmt.Sprintf("auth_session_info:%s", user.Email)
		sessionInfo := map[string]interface{}{
			"saveSession": creds.SaveSession,
			"userID":      user.ID,
		}
		sessionInfoJSON, _ := json.Marshal(sessionInfo)
		redisClient.Set(ctx, sessionInfoKey, string(sessionInfoJSON), 10*time.Minute)
	} else {
		log.Printf("Warning: Redis not available, code for %s: %s", user.Email, code)
	}

	// Отправляем код на email
	err = sendCodeToEmail(user.Email, code)
	if err != nil {
		log.Printf("⚠️  Failed to send email to %s: %v", user.Email, err)
		log.Printf("   Code saved in Redis, user can still verify it")
	} else {
		log.Printf("✅ Code sent successfully to %s", user.Email)
	}

	// Возвращаем успешный ответ без токена
	response := map[string]string{
		"message": "Code sent to email",
		"email":   user.Email,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	return
	*/

	// Простая авторизация - выдаем токен сразу
	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	// Сохранение сессии в Redis (только если пользователь выбрал эту опцию)
	saveSession := creds.SaveSession
	if saveSession && redisClient != nil {
		err = saveSessionToRedis(user.ID, tokenString, expirationTime)
		if err != nil {
			log.Printf("Warning: Failed to save session to Redis: %v", err)
		}
	}

	// Убираем пароль из ответа
	user.Password = ""

	// Вычисляем курс и семестр
	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = getCurrentSemester(user.EnrollmentYear)
	}

	// Формирование ответа
	response := AuthResponse{
		Token: tokenString,
		User:  user,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Обработчик выхода из системы
func logoutHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	// Получаем токен из заголовка
	authHeader := r.Header.Get("Authorization")
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")

	// Удаляем сессию из Redis
	if redisClient != nil {
		ctx := context.Background()
		sessionKey := fmt.Sprintf("session:%d:%s", claims.UserID, tokenString)
		sessionsKey := fmt.Sprintf("user_sessions:%d", claims.UserID)

		// Удаляем сессию
		redisClient.Del(ctx, sessionKey)
		redisClient.SRem(ctx, sessionsKey, sessionKey)
	}

	response := map[string]string{
		"message": "Logged out successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Генерация 6-значного кода
func generateCode() (string, error) {
	code := ""
	for i := 0; i < 6; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		code += strconv.Itoa(int(n.Int64()))
	}
	return code, nil
}

// Отправка кода на email
func sendCodeToEmail(email, code string) error {
	// Получаем настройки SMTP из переменных окружения
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPassword := os.Getenv("SMTP_PASSWORD")
	fromEmail := os.Getenv("FROM_EMAIL")

	// Если настройки не заданы, используем значения по умолчанию для тестирования
	if smtpHost == "" {
		smtpHost = "smtp.gmail.com"
	}
	if smtpPort == "" {
		smtpPort = "587"
	}
	if fromEmail == "" {
		fromEmail = smtpUser
	}

	// Если SMTP не настроен, просто логируем код (для разработки)
	if smtpUser == "" || smtpPassword == "" {
		log.Printf("⚠️  SMTP not configured. Email code for %s: %s", email, code)
		log.Printf("   To configure SMTP, set environment variables:")
		log.Printf("   - SMTP_HOST (default: smtp.gmail.com)")
		log.Printf("   - SMTP_PORT (default: 587)")
		log.Printf("   - SMTP_USER (your email)")
		log.Printf("   - SMTP_PASSWORD (your app password)")
		log.Printf("   - FROM_EMAIL (sender email, optional)")
		return nil
	}

	// Логируем попытку отправки
	log.Printf("📧 Attempting to send code to %s via %s:%s", email, smtpHost, smtpPort)

	// Формируем сообщение с правильным форматом MIME
	subject := "Код авторизации"
	body := fmt.Sprintf(`Здравствуйте!

Ваш код для входа в систему: %s

Код действителен в течение 10 минут.

Если вы не запрашивали этот код, проигнорируйте это письмо.`, code)

	// Правильный формат MIME для email
	message := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s", 
		fromEmail, email, subject, body)

	// Настройка аутентификации
	auth := smtp.PlainAuth("", smtpUser, smtpPassword, smtpHost)

	// Отправка письма
	addr := fmt.Sprintf("%s:%s", smtpHost, smtpPort)
	log.Printf("📤 Sending email to %s via %s", email, addr)
	
	err := smtp.SendMail(addr, auth, fromEmail, []string{email}, []byte(message))
	if err != nil {
		log.Printf("❌ Failed to send email to %s: %v", email, err)
		log.Printf("   Check SMTP settings:")
		log.Printf("   - SMTP_HOST: %s", smtpHost)
		log.Printf("   - SMTP_PORT: %s", smtpPort)
		log.Printf("   - SMTP_USER: %s", smtpUser)
		log.Printf("   - FROM_EMAIL: %s", fromEmail)
		return fmt.Errorf("failed to send email: %v", err)
	}

	log.Printf("✅ Email successfully sent to %s", email)
	return nil
}

// Обработчик запроса кода
func requestCodeHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
	}

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверяем, существует ли пользователь с таким email
	var user User
	err = db.QueryRow(
		`SELECT id, email FROM users WHERE email = $1`,
		req.Email,
	).Scan(&user.ID, &user.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Генерируем код
	code, err := generateCode()
	if err != nil {
		http.Error(w, "Failed to generate code", http.StatusInternalServerError)
		return
	}

	// Сохраняем код в Redis с TTL 10 минут
	if redisClient != nil {
		ctx := context.Background()
		codeKey := fmt.Sprintf("auth_code:%s", req.Email)
		err = redisClient.Set(ctx, codeKey, code, 10*time.Minute).Err()
		if err != nil {
			log.Printf("Failed to save code to Redis: %v", err)
			http.Error(w, "Failed to save code", http.StatusInternalServerError)
			return
		}
	} else {
		log.Printf("Warning: Redis not available, code for %s: %s", req.Email, code)
	}

	// Отправляем код на email
	err = sendCodeToEmail(req.Email, code)
	if err != nil {
		log.Printf("Failed to send email: %v", err)
		// Не возвращаем ошибку, если код сохранен в Redis
	}

	response := map[string]string{
		"message": "Code sent to email",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Обработчик проверки кода - завершает авторизацию
func verifyCodeHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверяем код в Redis
	if redisClient == nil {
		http.Error(w, "Redis not available", http.StatusServiceUnavailable)
		return
	}

	ctx := context.Background()
	codeKey := fmt.Sprintf("auth_code:%s", req.Email)
	storedCode, err := redisClient.Get(ctx, codeKey).Result()
	if err == redis.Nil {
		http.Error(w, "Code not found or expired", http.StatusUnauthorized)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Проверяем код
	if storedCode != req.Code {
		http.Error(w, "Invalid code", http.StatusUnauthorized)
		return
	}

	// Удаляем код после успешной проверки
	redisClient.Del(ctx, codeKey)

	// Получаем сохраненную информацию о сессии
	sessionInfoKey := fmt.Sprintf("auth_session_info:%s", req.Email)
	sessionInfoJSON, err := redisClient.Get(ctx, sessionInfoKey).Result()
	var saveSession bool = true
	var expectedUserID int = 0

	if err == nil {
		var sessionInfo map[string]interface{}
		if json.Unmarshal([]byte(sessionInfoJSON), &sessionInfo) == nil {
			if val, ok := sessionInfo["saveSession"].(bool); ok {
				saveSession = val
			}
			if val, ok := sessionInfo["userID"].(float64); ok {
				expectedUserID = int(val)
			}
		}
		// Удаляем информацию о сессии
		redisClient.Del(ctx, sessionInfoKey)
	}

	// Получаем пользователя из базы данных
	var user User
	err = db.QueryRow(
		`SELECT id, username, email, role, age, phone, first_name, last_name, 
		 study_group, enrollment_year, points, created_at 
		 FROM users WHERE email = $1`,
		req.Email,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age,
		&user.Phone, &user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear,
		&user.Points, &user.CreatedAt)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Дополнительная проверка безопасности: проверяем, что userID совпадает
	// Это предотвращает использование кода для другого пользователя
	if expectedUserID > 0 && user.ID != expectedUserID {
		http.Error(w, "Code verification failed: user mismatch", http.StatusUnauthorized)
		return
	}

	// Генерируем JWT токен
	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	// Сохранение сессии в Redis
	if saveSession && redisClient != nil {
		err = saveSessionToRedis(user.ID, tokenString, expirationTime)
		if err != nil {
			log.Printf("Warning: Failed to save session to Redis: %v", err)
		}
	}

	// Вычисляем курс и семестр
	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = getCurrentSemester(user.EnrollmentYear)
	}

	// Формирование ответа
	response := AuthResponse{
		Token: tokenString,
		User:  user,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Middleware для проверки JWT токена
func jwtMiddleware(next http.Handler) http.Handler {
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

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		// Проверка сессии в Redis (если Redis доступен)
		// Если сессия не найдена, но токен валиден, разрешаем доступ
		// (это позволяет работать с токенами, которые не были сохранены в Redis)
		if redisClient != nil {
			redisCtx := context.Background()
			sessionKey := fmt.Sprintf("session:%d:%s", claims.UserID, tokenString)
			exists, err := redisClient.Exists(redisCtx, sessionKey).Result()
			if err != nil {
				log.Printf("Warning: Failed to check session in Redis: %v", err)
				// Продолжаем работу, если Redis недоступен, но логируем ошибку
			} else if exists > 0 {
				// Сессия найдена в Redis - обновляем TTL
				redisClient.Expire(redisCtx, sessionKey, SessionTTL)
			}
			// Если сессия не найдена (exists == 0), но токен валиден, разрешаем доступ
			// Это позволяет работать с токенами, которые не были сохранены в Redis
		}

		// Добавляем claims в контекст
		requestCtx := context.WithValue(r.Context(), "claims", claims)
		next.ServeHTTP(w, r.WithContext(requestCtx))
	})
}

func utf8Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		next.ServeHTTP(w, r)
	})
}

// Middleware для проверки прав администратора
func adminMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := r.Context().Value("claims").(*Claims)
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

// Блок: Обработчик пользователей
// Получение всех пользователей
func getUsersHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`SELECT id, username, email, role, age, phone, first_name, last_name, 
		study_group, enrollment_year, points, created_at FROM users`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age,
			&user.Phone, &user.FirstName, &user.LastName, &user.StudyGroup,
			&user.EnrollmentYear, &user.Points, &user.CreatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		// Вычисляем курс и семестр
		if user.EnrollmentYear > 0 {
			user.Course, user.Semester = getCurrentSemester(user.EnrollmentYear)
		}
		users = append(users, user)
	}
	if err = rows.Err(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// Получение текущих пользователей в приложении
func getCurrentUserHandler(w http.ResponseWriter, r *http.Request) {
	// Извлечение токена из заголовка
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Authorization header required", http.StatusUnauthorized)
		return
	}

	// Проверка формата "Bearer <token>"
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenString == authHeader {
		http.Error(w, "Invalid token format", http.StatusUnauthorized)
		return
	}

	// Парсинг токена
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})

	if err != nil || !token.Valid {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	// Поиск пользователя в БД
	var user User
	err = db.QueryRow(
		`SELECT id, username, email, role, age, phone, first_name, last_name, 
		 study_group, enrollment_year, educational_institution, educational_direction, points, created_at 
		 FROM users WHERE id = $1`,
		claims.UserID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age,
		&user.Phone, &user.FirstName, &user.LastName, &user.StudyGroup,
		&user.EnrollmentYear, &user.EducationalInstitution, &user.EducationalDirection, &user.Points, &user.CreatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Вычисляем курс и семестр
	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = getCurrentSemester(user.EnrollmentYear)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// Профиль пользователя
func getProfileHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var user User
	err := db.QueryRow(`
        SELECT id, username, email, age, phone, points, created_at, 
		first_name, last_name, study_group, enrollment_year, educational_institution, educational_direction, role
        FROM users 
        WHERE id = $1
    `, claims.UserID).Scan(
		&user.ID, &user.Username, &user.Email,
		&user.Age, &user.Phone, &user.Points, &user.CreatedAt,
		&user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear, &user.EducationalInstitution, &user.EducationalDirection, &user.Role,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Вычисляем курс и семестр
	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = getCurrentSemester(user.EnrollmentYear)
	}

	// Получаем интересы в формате JSON
	var interestsJSON []byte
	var interests []string
	err = db.QueryRow("SELECT interests FROM user_interests WHERE user_id = $1", claims.UserID).Scan(&interestsJSON)
	if err == nil {
		json.Unmarshal(interestsJSON, &interests)
	} else if err == sql.ErrNoRows {
		interests = []string{}
	} else {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Получаем статистику пользователя
	var stats struct {
		Polls       float64 `json:"polls"`
		Hackathons  float64 `json:"hackathons"`
		Attendance  float64 `json:"attendance"`
		Conferences float64 `json:"conferences"`
		Bet         float64 `json:"bet"`
	}
	err = db.QueryRow(`
        SELECT polls, hackathons, attendance, conferences, bet 
        FROM user_stats 
        WHERE user_id = $1
    `, claims.UserID).Scan(
		&stats.Polls, &stats.Hackathons, &stats.Attendance,
		&stats.Conferences, &stats.Bet,
	)
	if err != nil && err != sql.ErrNoRows {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Получаем недельную активность
	rows, err := db.Query(`
        SELECT day, attendance, hackathons, polls 
        FROM weekly_activity 
        WHERE user_id = $1
    `, claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Создаем карту для хранения данных по дням
	weeklyActivityMap := make(map[string]map[string]interface{})

	// Инициализируем все дни недели с нулевыми значениями
	daysOfWeek := []string{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
	for _, day := range daysOfWeek {
		weeklyActivityMap[day] = map[string]interface{}{
			"day":        day,
			"attendance": 0,
			"hackathons": 0,
			"polls":      0,
		}
	}

	// Заполняем данными из БД
	for rows.Next() {
		var day string
		var attendance, hackathons, polls int
		if err := rows.Scan(&day, &attendance, &hackathons, &polls); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		weeklyActivityMap[day] = map[string]interface{}{
			"day":        day,
			"attendance": attendance,
			"hackathons": hackathons,
			"polls":      polls,
		}
	}

	// Преобразуем карту в массив в правильном порядке
	var weeklyActivity []map[string]interface{}
	for _, day := range daysOfWeek {
		weeklyActivity = append(weeklyActivity, weeklyActivityMap[day])
	}

	// Формируем ответ
	response := map[string]interface{}{
		"points":                  user.Points,
		"age":                     user.Age,
		"email":                   user.Email,
		"status":                  "Active",
		"role":                    user.Role,
		"interests":               interests,
		"stats":                   stats,
		"weekly_activity":         weeklyActivity,
		"avatar_url":              "https://example.com/avatar.png",
		"name":                    user.Username,
		"first_name":              user.FirstName,
		"last_name":               user.LastName,
		"study_group":             user.StudyGroup,
		"enrollment_year":         user.EnrollmentYear,
		"educational_institution": user.EducationalInstitution,
		"educational_direction":   user.EducationalDirection,
		"course":                  user.Course,
		"semester":                user.Semester,
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

func updateProfileHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var request struct {
		Username               string   `json:"username"`
		Email                  string   `json:"email"`
		Age                    int      `json:"age"`
		Status                 string   `json:"status"`
		Interests              []string `json:"interests"`
		FirstName              string   `json:"first_name"`
		LastName               string   `json:"last_name"`
		StudyGroup             string   `json:"study_group"`
		EnrollmentYear         int      `json:"enrollment_year"`
		EducationalInstitution string   `json:"educational_institution"`
		EducationalDirection   string   `json:"educational_direction"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Начинаем транзакцию
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Обновляем данные пользователя с новыми полями
	_, err = tx.Exec(`
        UPDATE users 
        SET username = $1, email = $2, age = $3, status = $4,
            first_name = $5, last_name = $6, study_group = $7, enrollment_year = $8, educational_institution = $9, educational_direction = $10
        WHERE id = $11
    `, request.Username, request.Email, request.Age, request.Status,
		request.FirstName, request.LastName, request.StudyGroup, request.EnrollmentYear, request.EducationalInstitution, request.EducationalDirection,
		claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	interestsJSON, err := json.Marshal(request.Interests)
	if err != nil {
		http.Error(w, "Failed to serialize interests", http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec(`
        INSERT INTO user_interests (user_id, interests) 
        VALUES ($1, $2) 
        ON CONFLICT (user_id) 
        DO UPDATE SET interests = $2
    `, claims.UserID, interestsJSON)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Коммитим транзакцию
	if err = tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Возвращаем обновленные данные профиля
	var user User
	err = db.QueryRow(`
        SELECT id, username, email, age, phone, points, status, created_at,
               first_name, last_name, study_group, enrollment_year
        FROM users 
        WHERE id = $1
    `, claims.UserID).Scan(
		&user.ID, &user.Username, &user.Email,
		&user.Age, &user.Phone, &user.Points, &user.Status, &user.CreatedAt,
		&user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Получаем обновленные интересы в формате JSON
	var interestsJSONResp []byte
	var interests []string
	err = db.QueryRow("SELECT interests FROM user_interests WHERE user_id = $1", claims.UserID).Scan(&interestsJSONResp)
	if err == nil {
		json.Unmarshal(interestsJSONResp, &interests)
	} else if err == sql.ErrNoRows {
		interests = []string{}
	} else {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"id":              user.ID,
		"username":        user.Username,
		"email":           user.Email,
		"age":             user.Age,
		"status":          user.Status,
		"interests":       interests,
		"first_name":      user.FirstName,
		"last_name":       user.LastName,
		"study_group":     user.StudyGroup,
		"enrollment_year": user.EnrollmentYear,
		"message":         "Profile updated successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func getCurrentSemester(enrollmentYear int) (int, int) {
	now := time.Now()
	currentYear := now.Year()
	currentMonth := int(now.Month())

	// Расчет курса
	course := currentYear - enrollmentYear
	if currentMonth >= 9 { // Если сентябрь или позже, то учебный год начался
		course++
	}

	// Расчет семестра (1 семестр: сентябрь-январь, 2 семестр: февраль-июнь)
	var semester int
	if currentMonth >= 2 && currentMonth <= 6 {
		semester = 2
	} else {
		semester = 1
	}

	return course, semester
}

// Блок: Обработчик опросника

// Создание опроса
func createSurveyHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var survey Survey
	if err := json.NewDecoder(r.Body).Decode(&survey); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	questionsJSON, err := json.Marshal(survey.Questions)
	if err != nil {
		http.Error(w, "Failed to serialize questions", http.StatusInternalServerError)
		return
	}

	err = db.QueryRow(
		`INSERT INTO surveys (title, description, questions, created_by, image_url, end_date) 
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, created_at`,
		survey.Title, survey.Description, questionsJSON, claims.UserID, survey.ImageURL, survey.EndDate,
	).Scan(&survey.ID, &survey.CreatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Формируем ответ с правильным форматом title
	response := map[string]interface{}{
		"id":          survey.ID,
		"description": survey.Description,
		"questions":   survey.Questions,
		"created_by":  survey.CreatedBy,
		"created_at":  survey.CreatedAt,
		"is_active":   survey.IsActive,
	}

	// Пытаемся распарсить title как JSON, если не получается - используем как строку
	var title interface{} = survey.Title
	var titleMap map[string]interface{}
	if err := json.Unmarshal([]byte(survey.Title), &titleMap); err == nil {
		title = titleMap
	}
	response["title"] = title

	if survey.ImageURL != "" {
		response["image_url"] = survey.ImageURL
	}
	if survey.EndDate != nil {
		response["end_date"] = survey.EndDate
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// Получение всех активных опросов
func getSurveysHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
        SELECT id, title, description, questions, created_by, created_at, image_url, end_date 
        FROM surveys WHERE is_active = true ORDER BY created_at DESC
    `)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type SurveyWithStats struct {
		ID            int         `json:"id"`
		Title         interface{} `json:"title"`
		Description   string      `json:"description"`
		Questions     []Question  `json:"questions"`
		CreatedBy     int         `json:"created_by"`
		CreatedAt     time.Time   `json:"created_at"`
		IsActive      bool        `json:"is_active"`
		ImageURL      string      `json:"image_url,omitempty"`
		EndDate       *time.Time  `json:"end_date,omitempty"`
		ResponseCount int         `json:"response_count"`
	}

	var surveysWithStats []SurveyWithStats
	for rows.Next() {
		var surveyID int
		var titleStr string
		var description string
		var questionsJSON []byte
		var createdBy int
		var createdAt time.Time
		var imageURL sql.NullString
		var endDate sql.NullTime

		err := rows.Scan(
			&surveyID, &titleStr, &description,
			&questionsJSON, &createdBy, &createdAt,
			&imageURL, &endDate,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Пытаемся распарсить title как JSON, если не получается - используем как строку
		var title interface{} = titleStr
		var titleMap map[string]interface{}
		if err := json.Unmarshal([]byte(titleStr), &titleMap); err == nil {
			// Если успешно распарсили как JSON, используем объект
			title = titleMap
		}

		var questions []Question
		if err := json.Unmarshal(questionsJSON, &questions); err != nil {
			http.Error(w, "Failed to parse questions", http.StatusInternalServerError)
			return
		}

		var endDatePtr *time.Time
		if endDate.Valid {
			endDatePtr = &endDate.Time
		}

		// Подсчитываем количество прошедших опросник
		var responseCount int
		err = db.QueryRow(
			"SELECT COUNT(*) FROM user_responses WHERE survey_id = $1",
			surveyID,
		).Scan(&responseCount)
		if err != nil {
			responseCount = 0
		}

		surveyWithStats := SurveyWithStats{
			ID:            surveyID,
			Title:         title,
			Description:   description,
			Questions:     questions,
			CreatedBy:     createdBy,
			CreatedAt:     createdAt,
			IsActive:      true,
			ResponseCount: responseCount,
		}

		if imageURL.Valid {
			surveyWithStats.ImageURL = imageURL.String
		}
		if endDatePtr != nil {
			surveyWithStats.EndDate = endDatePtr
		}

		surveysWithStats = append(surveysWithStats, surveyWithStats)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(surveysWithStats)
}

// Прохождение опроса
func submitSurveyHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var submission struct {
		SurveyID int           `json:"survey_id"`
		Answers  []interface{} `json:"answers"`
	}

	if err := json.NewDecoder(r.Body).Decode(&submission); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверяем, не проходил ли пользователь уже этот опрос
	var alreadySubmitted bool
	err := db.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM user_responses WHERE user_id = $1 AND survey_id = $2)",
		claims.UserID, submission.SurveyID,
	).Scan(&alreadySubmitted)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if alreadySubmitted {
		http.Error(w, "Survey already submitted", http.StatusBadRequest)
		return
	}

	answersJSON, err := json.Marshal(submission.Answers)
	if err != nil {
		http.Error(w, "Failed to serialize answers", http.StatusInternalServerError)
		return
	}

	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Сохраняем ответы
	_, err = tx.Exec(
		"INSERT INTO user_responses (user_id, survey_id, answers) VALUES ($1, $2, $3)",
		claims.UserID, submission.SurveyID, answersJSON,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Получаем баллы за опрос
	var pointsToAdd int
	err = tx.QueryRow(
		"SELECT points FROM survey_points WHERE survey_id = $1",
		submission.SurveyID,
	).Scan(&pointsToAdd)

	if err != nil {
		// Если баллы не установлены, используем количество ответов
		if err == sql.ErrNoRows {
			pointsToAdd = len(submission.Answers)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	// Начисляем баллы
	_, err = tx.Exec(
		"UPDATE users SET points = points + $1 WHERE id = $2",
		pointsToAdd, claims.UserID,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Получаем обновленные данные пользователя
	var user User
	err = db.QueryRow(
		`SELECT id, username, email, first_name, last_name, study_group, enrollment_year, points 
		 FROM users WHERE id = $1`,
		claims.UserID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.FirstName, &user.LastName,
		&user.StudyGroup, &user.EnrollmentYear, &user.Points)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Вычисляем курс и семестр
	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = getCurrentSemester(user.EnrollmentYear)
	}

	response := map[string]interface{}{
		"message":      "Survey submitted successfully",
		"points_added": pointsToAdd,
		"total_points": user.Points,
		"user":         user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Обработчик для установки баллов за опрос
func setSurveyPointsHandler(w http.ResponseWriter, r *http.Request) {
	var request struct {
		SurveyID int `json:"survey_id"`
		Points   int `json:"points"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверка на существующую запись опросника
	var exists bool
	err := db.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM survey_points WHERE survey_id = $1)",
		request.SurveyID,
	).Scan(&exists)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if exists {
		// Обновление существующей записи
		_, err = db.Exec(
			"UPDATE survey_points SET points = $1 WHERE survey_id = $2",
			request.Points,
			request.SurveyID,
		)
	} else {
		// Создание новой записи
		_, err = db.Exec(
			"INSERT INTO survey_points (survey_id, points) VALUES ($1, $2)",
			request.SurveyID,
			request.Points,
		)
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Survey points updated successfully"})
}

// Получение статистики ответов по опроснику (только для админов)
func getSurveyStatisticsHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	surveyIDStr := vars["id"]
	surveyID, err := strconv.Atoi(surveyIDStr)
	if err != nil {
		http.Error(w, "Invalid survey ID", http.StatusBadRequest)
		return
	}

	// Получаем опросник
	var survey Survey
	var questionsJSON []byte
	err = db.QueryRow(`
		SELECT id, title, description, questions, created_by, created_at, is_active
		FROM surveys WHERE id = $1
	`, surveyID).Scan(
		&survey.ID, &survey.Title, &survey.Description,
		&questionsJSON, &survey.CreatedBy, &survey.CreatedAt, &survey.IsActive,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Survey not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := json.Unmarshal(questionsJSON, &survey.Questions); err != nil {
		http.Error(w, "Failed to parse questions", http.StatusInternalServerError)
		return
	}

	// Получаем все ответы на этот опросник
	rows, err := db.Query(`
		SELECT answers FROM user_responses WHERE survey_id = $1
	`, surveyID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var allAnswers [][]interface{}
	for rows.Next() {
		var answersJSON []byte
		if err := rows.Scan(&answersJSON); err != nil {
			continue
		}
		var answers []interface{}
		if err := json.Unmarshal(answersJSON, &answers); err != nil {
			continue
		}
		allAnswers = append(allAnswers, answers)
	}

	// Подсчитываем статистику по каждому вопросу
	type QuestionStatistics struct {
		QuestionIndex int                `json:"question_index"`
		QuestionText  string             `json:"question_text"`
		Options       []string           `json:"options"`
		Statistics    map[string]int     `json:"statistics"`
		Percentages   map[string]float64 `json:"percentages"`
	}

	var statistics []QuestionStatistics
	totalResponses := len(allAnswers)

	for i, question := range survey.Questions {
		optionCounts := make(map[string]int)

		// Инициализируем счетчики для всех вариантов ответа
		for _, option := range question.Options {
			optionCounts[option] = 0
		}

		// Подсчитываем ответы
		for _, userAnswers := range allAnswers {
			if i < len(userAnswers) {
				answerIndex, ok := userAnswers[i].(float64)
				if ok && int(answerIndex) >= 0 && int(answerIndex) < len(question.Options) {
					option := question.Options[int(answerIndex)]
					optionCounts[option]++
				}
			}
		}

		// Вычисляем проценты
		percentages := make(map[string]float64)
		for option, count := range optionCounts {
			if totalResponses > 0 {
				percentages[option] = float64(count) / float64(totalResponses) * 100
			} else {
				percentages[option] = 0
			}
		}

		statistics = append(statistics, QuestionStatistics{
			QuestionIndex: i + 1,
			QuestionText:  question.Text,
			Options:       question.Options,
			Statistics:    optionCounts,
			Percentages:   percentages,
		})
	}

	response := map[string]interface{}{
		"survey_id":       surveyID,
		"total_responses": totalResponses,
		"questions":       statistics,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Блок для работы с событиями
// Создание события
func createEventHandler(w http.ResponseWriter, r *http.Request) {
	var event Event
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		log.Printf("Error decoding event: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	log.Printf("Creating event: %+v", event)

	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	// Устанавливаем тип по умолчанию, если не указан
	if event.Type == "" {
		event.Type = "Conference"
	}

	err := db.QueryRow(
		`INSERT INTO events (title, description, type, start_date, end_date, user_id) 
		VALUES ($1, $2, $3, $4, $5, $6) 
		RETURNING id, created_at`,
		event.Title,
		event.Description,
		event.Type,
		event.StartDate,
		event.EndDate,
		claims.UserID,
	).Scan(&event.ID, &event.CreatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(event)
}

// Автоматическое удаление старых завершённых событий
// Удаляет события, которые завершились более N дней назад (по умолчанию 3 дня)
func cleanupOldEvents() error {
	// Получаем количество дней из переменной окружения или используем значение по умолчанию
	retentionDays := DefaultEventRetentionDays
	if envDays := os.Getenv("EVENT_RETENTION_DAYS"); envDays != "" {
		if days, err := strconv.Atoi(envDays); err == nil && days > 0 {
			retentionDays = days
		}
	}

	// Вычисляем дату N дней назад
	cutoffDate := time.Now().AddDate(0, 0, -retentionDays)

	// Удаляем события, где end_date меньше cutoffDate
	result, err := db.Exec(`
		DELETE FROM events 
		WHERE end_date IS NOT NULL AND end_date < $1
	`, cutoffDate)

	if err != nil {
		log.Printf("Error cleaning up old events: %v", err)
		return err
	}

	// Логируем количество удалённых событий (опционально)
	if rowsAffected, err := result.RowsAffected(); err == nil && rowsAffected > 0 {
		log.Printf("Cleaned up %d old events (older than %d days)", rowsAffected, retentionDays)
	}

	return nil
}

// Получение всех событий
func getEventsHandler(w http.ResponseWriter, r *http.Request) {
	// Автоматически удаляем старые завершённые события перед получением списка
	cleanupOldEvents()

	rows, err := db.Query(`
		SELECT id, title, description, type, start_date, end_date, user_id, created_at FROM events ORDER BY start_date DESC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var events []Event
	for rows.Next() {
		var event Event
		err := rows.Scan(
			&event.ID,
			&event.Title,
			&event.Description,
			&event.Type,
			&event.StartDate,
			&event.EndDate,
			&event.UserID,
			&event.CreatedAt,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		events = append(events, event)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(events)
}

// Обновление события
func updateEventHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	var event Event
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.Exec(`
		UPDATE events 
		SET title = $1, description = $2, type = $3, start_date = $4, end_date = $5 
		WHERE id = $6`,
		event.Title,
		event.Description,
		event.Type,
		event.StartDate,
		event.EndDate,
		eventID,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// Удаление события
func deleteEventHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	_, err := db.Exec(`DELETE FROM events WHERE id = $1`, eventID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// Блок для работы с товарами

// Получение всех товаров
func getProductsHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
		SELECT id, name, description, price, created_at FROM products ORDER BY created_at DESC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var product Product
		err := rows.Scan(
			&product.ID,
			&product.Name,
			&product.Description,
			&product.Price,
			&product.CreatedAt,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		products = append(products, product)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)

}

// Создание товара
func createProductHandler(w http.ResponseWriter, r *http.Request) {
	var products Product
	if err := json.NewDecoder(r.Body).Decode(&products); err != nil {
		log.Printf("Error decoding event: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	log.Printf("Creating event: %+v", products)

	_, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	err := db.QueryRow(
		`INSERT INTO products (name, description, price) VALUES ($1, $2, $3) RETURNING id, created_at`,
		products.Name,
		products.Description,
		products.Price,
	).Scan(&products.ID, &products.CreatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(products)
}

// Обновление товара
func updateProductHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	productID := vars["id"]

	var product Product
	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.Exec(`
		UPDATE products 
		SET name = $1, description = $2, price = $3 
		WHERE id = $4`,
		product.Name,
		product.Description,
		product.Price,
		productID,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// Удаление товара
func deleteProductHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	productID := vars["id"]

	_, err := db.Exec(`DELETE FROM products WHERE id = $1`, productID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)

}

// CORS Middleware
func enableCORS(next http.Handler) http.Handler {
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
