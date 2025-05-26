package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

var db *sql.DB
var jwtKey []byte

const MaxSessionsPerUser = 5

// User структура для хранения данных пользователя
type User struct {
	ID        int    `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	Password  string `json:"password"`
	Role      string `json:"role"`
	Age       int    `json:"age"`
	Phone     string `json:"phone"`
	Points    int    `json:"points"`
	CreatedAt string `json:"created_at"`
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
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	UserID      int       `json:"user_id"`
	CreatedAt   time.Time `json:"created_at"`
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

	// Настройка маршрутов
	router := mux.NewRouter()
	router.Use(enableCORS)

	// Маршруты регистрации и авторизации
	router.HandleFunc("/register", registerHandler).Methods("POST", "OPTIONS")
	router.HandleFunc("/login", loginHandler).Methods("POST", "OPTIONS")
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

	// Маршруты получения/хранения опросника
	router.Handle("/save-responses", jwtMiddleware(http.HandlerFunc(saveResponsesHandler))).Methods("POST", "OPTIONS")
	router.Handle("/get-responses", jwtMiddleware(http.HandlerFunc(getResponsesHandler))).Methods("GET", "OPTIONS")

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

	// Маршрут для добавления баллов
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
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
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
		username TEXT NOT NULL UNIQUE,
		email TEXT NOT NULL UNIQUE,
		password TEXT NOT NULL,
		role TEXT NOT NULL DEFAULT 'student',
		age INTEGER,
		phone TEXT,
		points INTEGER NOT NULL DEFAULT 0,
		created_at TIMESTAMP NOT NULL
	);
	`
	_, err = db.Exec(createTableSQL)
	if err != nil {
		log.Fatal(err)
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
		start_date TIMESTAMP NOT NULL,
		end_date TIMESTAMP NOT NULL,
		user_id INTEGER REFERENCES users(id),
		created_at TIMESTAMP NOT NULL DEFAULT NOW()
	);`

	_, err = db.Exec(createEventsTableSQL)
	if err != nil {
		log.Fatal(err)
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
		user_id INTEGER REFERENCES users(id),
		interest TEXT NOT NULL,
		PRIMARY KEY (user_id, interest)
	);
	`
	_, err = db.Exec(createUserInterestsTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	// Таблица для хранения статистики пользователей
	createUserStatsTableSQL := `
	CREATE TABLE IF NOT EXISTS user_stats (
		user_id INTEGER REFERENCES users(id),
		polls INTEGER DEFAULT 0,
		hackathons INTEGER DEFAULT 0,
		attendance FLOAT DEFAULT 0,
		conferences INTEGER DEFAULT 0,
		bet INTEGER DEFAULT 0
	);
	`

	_, err = db.Exec(createUserStatsTableSQL)
	if err != nil {
		log.Fatal(err)
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
	router := mux.NewRouter()
	router.Use(enableCORS)
}

// Блок: Регистрация и авторизация/Присвоение JWT-токена
// Функция Регистрации
func registerHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверка, что все обязательные поля заполнены
	if user.Username == "" || user.Email == "" || user.Password == "" {
		http.Error(w, "Username, email and password are required", http.StatusBadRequest)
		return
	}

	// Установка роли по умолчанию
	user.Role = "student"

	// Проверка возраста (опционально)
	if user.Age < 0 {
		http.Error(w, "Age cannot be negative", http.StatusBadRequest)
		return
	}

	// Хеширование пароля
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	user.CreatedAt = time.Now().Format(time.RFC3339)
	user.Password = string(hashedPassword)

	// Вставка пользователя в базу данных и получение ID
	err = db.QueryRow(
		"INSERT INTO users (username, email, password, role, age, phone, points, created_at) VALUES ($1, $2, $3, $4, $5, $6, 0, $7) RETURNING id, points",
		user.Username, user.Email, user.Password, user.Role, user.Age, user.Phone, user.CreatedAt,
	).Scan(&user.ID, &user.Points)

	if err != nil {
		// Проверка на дубликат username или email, а также phone
		if err.Error() == "pq: duplicate key value violates unique constraint \"users_username_key\"" {
			http.Error(w, "Username already exists", http.StatusConflict)
			return
		}
		if err.Error() == "pq: duplicate key value violates unique constraint \"users_email_key\"" {
			http.Error(w, "Email already exists", http.StatusConflict)
			return
		}
		if err.Error() == "pq: duplicate key value violates unique constraint \"users_phone_key\"" {
			http.Error(w, "Phone already exists", http.StatusConflict)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Убираем пароль из ответа
	user.Password = ""

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// Функция авторизации
func loginHandler(w http.ResponseWriter, r *http.Request) {
	var creds struct {
		EmailOrPhone string `json:"emailOrPhone"`
		Password     string `json:"password"`
	}

	err := json.NewDecoder(r.Body).Decode(&creds)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Поиск пользователя в базе данных
	var user User
	err = db.QueryRow(
		"SELECT id, username, email, password, role, age, phone, created_at FROM users WHERE phone = $1 OR email = $1",
		creds.EmailOrPhone,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Password, &user.Role, &user.Age, &user.Phone, &user.CreatedAt)
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

	// Убираем пароль из ответа
	user.Password = ""

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

		// Добавляем claims в контекст
		ctx := context.WithValue(r.Context(), "claims", claims)
		next.ServeHTTP(w, r.WithContext(ctx))
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
	rows, err := db.Query("SELECT id, username, email, role, age, phone, created_at FROM users")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age, &user.Phone, &user.CreatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
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
		"SELECT id, username, email, role, age, phone, created_at FROM users WHERE id = $1",
		claims.UserID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age, &user.Phone, &user.CreatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
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
        SELECT id, username, email, age, phone, points, created_at 
        FROM users 
        WHERE id = $1
    `, claims.UserID).Scan(
		&user.ID, &user.Username, &user.Email,
		&user.Age, &user.Phone, &user.Points, &user.CreatedAt,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rows, err := db.Query("SELECT interest FROM user_interests WHERE user_id = $1", claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var interests []string
	for rows.Next() {
		var interest string
		if err := rows.Scan(&interest); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		interests = append(interests, interest)
	}

	var stats struct {
		Polls       int     `json:"polls"`
		Hackathons  int     `json:"hackathons"`
		Attendance  float64 `json:"attendance"`
		Conferences int     `json:"conferences"`
		Bet         int     `json:"bet"`
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

	rows, err = db.Query(`
        SELECT day, attendance, hackathons, polls 
        FROM weekly_activity 
        WHERE user_id = $1
    `, claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var weeklyActivity []map[string]interface{}
	for rows.Next() {
		var day string
		var attendance, hackathons, polls int
		if err := rows.Scan(&day, &attendance, &hackathons, &polls); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		weeklyActivity = append(weeklyActivity, map[string]interface{}{
			"day":        day,
			"attendance": attendance,
			"hackathons": hackathons,
			"polls":      polls,
		})
	}

	response := map[string]interface{}{
		"age":             user.Age,
		"email":           user.Email,
		"status":          "Active",
		"interests":       interests,
		"stats":           stats,
		"weekly_activity": weeklyActivity,
		"avatar_url":      "https://example.com/avatar.png",
		"name":            user.Username,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Блок: Обработчик опросника
// Обработчик сохранения ответов
func saveResponsesHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var responses struct {
		Answers  []int `json:"answers"`
		SurveyID int   `json:"survey_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&responses); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Сериализация ответов в JSON
	answersJSON, err := json.Marshal(responses.Answers)
	if err != nil {
		http.Error(w, "Failed to serialize answers", http.StatusInternalServerError)
		return
	}

	// Начала транзакции баллов
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	_, err = db.Exec(
		"INSERT INTO user_responses (user_id, answers, survey_id) VALUES ($1, $2, $3)",
		claims.UserID,
		answersJSON,
		responses.SurveyID,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Получение кол-ва баллов за опрос
	var pointsToAdd int
	err = tx.QueryRow(
		"SELECT points FROM survey_points WHERE survey_id = $1",
		responses.SurveyID,
	).Scan(&pointsToAdd)
	if err != nil {
		// Используем кол-во ответов как баллы, если баллы не были выставлены изначально
		if err == sql.ErrNoRows {
			pointsToAdd = len(responses.Answers)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	_, err = tx.Exec(
		"UPDATE users SET points = points + $1 WHERE id = $2",
		pointsToAdd,
		claims.UserID,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Завершаем транзакцию баллов
	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Обновляем данные пользователя
	var user User
	err = db.QueryRow(
		"SELECT id, username, email, role, age, phone, points, created_at FROM users WHERE id = $1", claims.UserID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age, &user.Phone, &user.Points, &user.CreatedAt)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := struct {
		Message     string `json:"message"`
		PointsAdded int    `json:"points_added"`
		TotalPoints int    `json:"total_points"`
		User        User   `json:"user"`
	}{
		Message:     "Ответ сохранён успешно",
		PointsAdded: pointsToAdd,
		TotalPoints: user.Points,
		User:        user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	w.WriteHeader(http.StatusCreated)
}

// Обработчик получения ответов
func getResponsesHandler(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value("claims").(*Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	rows, err := db.Query(
		"SELECT answers, created_at FROM user_responses WHERE user_id = $1 ORDER BY created_at DESC",
		claims.UserID,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var responses []map[string]interface{}
	for rows.Next() {
		var answers []int
		var created_At time.Time

		if err := rows.Scan(&answers, &created_At); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		responses = append(responses, map[string]interface{}{
			"answers":    answers,
			"created_at": created_At.Format(time.RFC3339),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(responses)
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

	err := db.QueryRow(
		`INSERT INTO events (title, description, start_date, end_date, user_id) 
		VALUES ($1, $2, $3, $4, $5) 
		RETURNING id, created_at`,
		event.Title,
		event.Description,
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

// Получение всех событий
func getEventsHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
		SELECT id, title, description, start_date, end_date, user_id, created_at FROM events ORDER BY start_date DESC
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
		SET title = $1, description = $2, start_date = $3, end_date = $4 
		WHERE id = $5`,
		event.Title,
		event.Description,
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
