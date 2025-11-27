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
	ID             int    `json:"id"`
	FirstName      string `json:"first_name"`
	LastName       string `json:"last_name"`
	Username       string `json:"username"`
	Email          string `json:"email"`
	Password       string `json:"password"`
	StudyGroup     string `json:"study_group"`
	EnrollmentYear int    `json:"enrollment_year"`
	Semester       int    `json:"semester"`
	Course         int    `json:"course"`
	Role           string `json:"role"`
	Age            int    `json:"age"`
	Phone          string `json:"phone"`
	Points         int    `json:"points"`
	Status         string `json:"status"`
	CreatedAt      string `json:"created_at"`
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
	router.Use(utf8Middleware)

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
	router.Handle("/profile-update", jwtMiddleware(http.HandlerFunc(updateProfileHandler))).Methods("POST", "OPTIONS")

	// Маршруты получения/хранения опросника
	router.Handle("/surveys", jwtMiddleware(http.HandlerFunc(getSurveysHandler))).Methods("GET", "OPTIONS")
	router.Handle("/createsurvey", jwtMiddleware(adminMiddleware(http.HandlerFunc(createSurveyHandler)))).Methods("POST", "OPTIONS")
	router.Handle("/submitsurvey", jwtMiddleware(http.HandlerFunc(submitSurveyHandler))).Methods("POST", "OPTIONS")

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
		username TEXT NOT NULL UNIQUE,
		study_group TEXT,
		enrollment_year INTEGER,
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

	createSurveysTableSQL := `
	CREATE TABLE IF NOT EXISTS surveys (
		id SERIAL PRIMARY KEY,
		title TEXT NOT NULL,
		description TEXT,
		questions JSONB NOT NULL,
		created_by INTEGER REFERENCES users(id),
		created_at TIMESTAMP NOT NULL DEFAULT NOW(),
		is_active BOOLEAN DEFAULT true
	);`

	_, err = db.Exec(createSurveysTableSQL)
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
}

// Блок: Регистрация и авторизация/Присвоение JWT-токена
// Функция Регистрации
func registerHandler(w http.ResponseWriter, r *http.Request) {
	var user struct {
		Username       string `json:"username"`
		Email          string `json:"email"`
		Password       string `json:"password"`
		FirstName      string `json:"first_name"`
		LastName       string `json:"last_name"`
		StudyGroup     string `json:"study_group"`
		EnrollmentYear int    `json:"enrollment_year"`
		Age            int    `json:"age"`
		Phone          string `json:"phone"`
	}

	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Проверка обязательных полей
	if user.Username == "" || user.Email == "" || user.Password == "" {
		http.Error(w, "Username, email and password are required", http.StatusBadRequest)
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
		`INSERT INTO users (username, email, password, first_name, last_name, study_group, enrollment_year, age, phone, created_at) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
		 RETURNING id, points`,
		user.Username, user.Email, string(hashedPassword), user.FirstName, user.LastName,
		user.StudyGroup, user.EnrollmentYear, user.Age, user.Phone, createdAt,
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

		// Добавляем claims в контекст
		ctx := context.WithValue(r.Context(), "claims", claims)
		next.ServeHTTP(w, r.WithContext(ctx))
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
		 study_group, enrollment_year, points, created_at 
		 FROM users WHERE id = $1`,
		claims.UserID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Role, &user.Age,
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
		first_name, last_name, study_group, enrollment_year
        FROM users 
        WHERE id = $1
    `, claims.UserID).Scan(
		&user.ID, &user.Username, &user.Email,
		&user.Age, &user.Phone, &user.Points, &user.CreatedAt,
		&user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear,
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

	// Формируем ответ
	response := map[string]interface{}{
		"points":          user.Points,
		"age":             user.Age,
		"email":           user.Email,
		"status":          "Active",
		"interests":       interests,
		"stats":           stats,
		"weekly_activity": weeklyActivity,
		"avatar_url":      "https://example.com/avatar.png",
		"name":            user.Username,
		"first_name":      user.FirstName,
		"last_name":       user.LastName,
		"study_group":     user.StudyGroup,
		"enrollment_year": user.EnrollmentYear,
		"course":          user.Course,
		"semester":        user.Semester,
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
		Username       string   `json:"username"`
		Email          string   `json:"email"`
		Age            int      `json:"age"`
		Status         string   `json:"status"`
		Interests      []string `json:"interests"`
		FirstName      string   `json:"first_name"`
		LastName       string   `json:"last_name"`
		StudyGroup     string   `json:"study_group"`
		EnrollmentYear int      `json:"enrollment_year"`
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
            first_name = $5, last_name = $6, study_group = $7, enrollment_year = $8
        WHERE id = $9
    `, request.Username, request.Email, request.Age, request.Status,
		request.FirstName, request.LastName, request.StudyGroup, request.EnrollmentYear,
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
		`INSERT INTO surveys (title, description, questions, created_by) 
         VALUES ($1, $2, $3, $4) RETURNING id, created_at`,
		survey.Title, survey.Description, questionsJSON, claims.UserID,
	).Scan(&survey.ID, &survey.CreatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(survey)
}

// Получение всех активных опросов
func getSurveysHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
        SELECT id, title, description, questions, created_by, created_at 
        FROM surveys WHERE is_active = true ORDER BY created_at DESC
    `)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var surveys []Survey
	for rows.Next() {
		var survey Survey
		var questionsJSON []byte

		err := rows.Scan(
			&survey.ID, &survey.Title, &survey.Description,
			&questionsJSON, &survey.CreatedBy, &survey.CreatedAt,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if err := json.Unmarshal(questionsJSON, &survey.Questions); err != nil {
			http.Error(w, "Failed to parse questions", http.StatusInternalServerError)
			return
		}

		surveys = append(surveys, survey)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(surveys)
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
