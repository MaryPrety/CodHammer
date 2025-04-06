package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

var db *sql.DB
var jwtKey []byte

// User структура для хранения данных пользователя
type User struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	Password  string `json:"password"`
	Role      string `json:"role"`
	Age       int    `json:"age"`
	Phone     string `json:"phone"`
	CreatedAt string `json:"created_at"`
}

// AuthResponse структура для ответа при авторизации
type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

// Claims структура для JWT
type Claims struct {
	Username string `json:"username"`
	jwt.StandardClaims
}

func main() {
	// Инициализация JWT ключа
	initJWTKey()

	// Инициализация подключения к PostgreSQL
	initDB()
	defer db.Close()

	// Настройка маршрутов
	router := mux.NewRouter()
	router.HandleFunc("/register", registerHandler).Methods("POST")
	router.HandleFunc("/login", loginHandler).Methods("POST")
	router.HandleFunc("/users", getUsersHandler).Methods("GET")

	// Запуск сервера
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Server is running on port %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, router))
}

// Инициализация JWT ключа
func initJWTKey() {
	if key := os.Getenv("JWT_SECRET_KEY"); key != "" {
		jwtKey = []byte(key)
		fmt.Println("Using JWT key from environment variable")
		return
	}

	var err error
	jwtKey, err = generateRandomKey(32)
	if err != nil {
		log.Fatal("Failed to generate JWT key: ", err)
	}

	fmt.Printf("Generated JWT key: %s\n", base64.StdEncoding.EncodeToString(jwtKey))
	fmt.Println("ПРИ ПОСТУПЛЕНИИ В PRODUCTION - ЗАМЕНИТЬ НА ДОБАВЛЕНИЕ КЛЮЧА ЧЕРЕЗ КОНФ.ФАЙЛ!")
}

func generateRandomKey(length int) ([]byte, error) {
	key := make([]byte, length)
	_, err := rand.Read(key)
	if err != nil {
		return nil, err
	}
	return key, nil
}

// Инициализация PostgreSQL
func initDB() {
	var err error
	// Подключение к PostgreSQL
	connStr := "user=postgres dbname=users password=1973 host=localhost sslmode=disable"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}

	// Проверка подключения
	err = db.Ping()
	if err != nil {
		log.Fatal(err)
	}

	// Создание таблицы пользователей, если она не существует
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		username TEXT NOT NULL UNIQUE,
		email TEXT NOT NULL UNIQUE,
		password TEXT NOT NULL,
		role TEXT NOT NULL DEFAULT 'student',
		age INTEGER,
		phone TEXT,
		created_at TIMESTAMP NOT NULL
	);
	`
	_, err = db.Exec(createTableSQL)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Successfully connected to PostgreSQL")

	router := mux.NewRouter()
	router.Use(enableCORS)
}

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
		"INSERT INTO users (username, email, password, role, age, phone, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id",
		user.Username, user.Email, user.Password, user.Role, user.Age, user.Phone, user.CreatedAt,
	).Scan(&user.ID)

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

// Middleware для проверки JWT
func authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Authorization header required", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		claims := &Claims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	var creds struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	err := json.NewDecoder(r.Body).Decode(&creds)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Поиск пользователя в базе данных
	var user User
	err = db.QueryRow(
		"SELECT id, username, email, password, role, age, phone, created_at FROM users WHERE username = $1 OR email = $1",
		creds.Username,
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
		Username: user.Username,
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

// CORS Middleware
func enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			return
		}

		next.ServeHTTP(w, r)
	})
}
