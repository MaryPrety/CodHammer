package auth

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/go-redis/redis/v8"
	"golang.org/x/crypto/bcrypt"

	"backend/internal/middleware"
	"backend/internal/models"
	"backend/internal/services/email"
	"backend/internal/services/session"
	"backend/internal/services/utils"
)

// Handler содержит зависимости для auth handlers
type Handler struct {
	DB          *sql.DB
	Redis       *redis.Client
	JWTKey      []byte
}

// Register обрабатывает регистрацию пользователя
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
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

	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

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

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	createdAt := time.Now().Format(time.RFC3339)

	var userID int
	var points int
	err = h.DB.QueryRow(
		`INSERT INTO users (username, email, password, first_name, last_name, study_group, enrollment_year, educational_institution, educational_direction, age, phone, created_at) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
		 RETURNING id, points`,
		user.Username, user.Email, string(hashedPassword), user.FirstName, user.LastName,
		user.StudyGroup, user.EnrollmentYear, user.EducationalInstitution, user.EducationalDirection, user.Age, user.Phone, createdAt,
	).Scan(&userID, &points)

	if err != nil {
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

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

// Login обрабатывает авторизацию
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var creds struct {
		EmailOrPhone string `json:"emailOrPhone"`
		Password     string `json:"password"`
		SaveSession  bool   `json:"saveSession"`
	}

	if err := json.NewDecoder(r.Body).Decode(&creds); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var user models.User
	err := h.DB.QueryRow(
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

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(creds.Password)); err != nil {
		http.Error(w, "Invalid password", http.StatusUnauthorized)
		return
	}

	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &models.Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(h.JWTKey)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	if creds.SaveSession && h.Redis != nil {
		if err := session.SaveToRedis(h.Redis, user.ID, tokenString, expirationTime); err != nil {
			log.Printf("Warning: Failed to save session to Redis: %v", err)
		}
	}

	user.Password = ""
	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = utils.GetCurrentSemester(user.EnrollmentYear)
	}

	response := models.AuthResponse{
		Token: tokenString,
		User:  user,
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

// Logout обрабатывает выход из системы
func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	authHeader := r.Header.Get("Authorization")
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")

	if h.Redis != nil {
		ctx := context.Background()
		sessionKey := fmt.Sprintf("session:%d:%s", claims.UserID, tokenString)
		sessionsKey := fmt.Sprintf("user_sessions:%d", claims.UserID)
		h.Redis.Del(ctx, sessionKey)
		h.Redis.SRem(ctx, sessionsKey, sessionKey)
	}

	response := map[string]string{"message": "Logged out successfully"}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

// RequestCode обрабатывает запрос кода на email
func (h *Handler) RequestCode(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var user models.User
	if err := h.DB.QueryRow(`SELECT id, email FROM users WHERE email = $1`, req.Email).Scan(&user.ID, &user.Email); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	code, err := utils.GenerateCode()
	if err != nil {
		http.Error(w, "Failed to generate code", http.StatusInternalServerError)
		return
	}

	if h.Redis != nil {
		ctx := context.Background()
		codeKey := fmt.Sprintf("auth_code:%s", req.Email)
		if err := h.Redis.Set(ctx, codeKey, code, 10*time.Minute).Err(); err != nil {
			log.Printf("Failed to save code to Redis: %v", err)
			http.Error(w, "Failed to save code", http.StatusInternalServerError)
			return
		}
	} else {
		log.Printf("Warning: Redis not available, code for %s: %s", req.Email, code)
	}

	if err := email.SendCode(req.Email, code); err != nil {
		log.Printf("Failed to send email: %v", err)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]string{"message": "Code sent to email"})
}

// VerifyCode обрабатывает проверку кода и завершает авторизацию
func (h *Handler) VerifyCode(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if h.Redis == nil {
		http.Error(w, "Redis not available", http.StatusServiceUnavailable)
		return
	}

	ctx := context.Background()
	codeKey := fmt.Sprintf("auth_code:%s", req.Email)
	storedCode, err := h.Redis.Get(ctx, codeKey).Result()
	if err == redis.Nil {
		http.Error(w, "Code not found or expired", http.StatusUnauthorized)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if storedCode != req.Code {
		http.Error(w, "Invalid code", http.StatusUnauthorized)
		return
	}

	h.Redis.Del(ctx, codeKey)

	sessionInfoKey := fmt.Sprintf("auth_session_info:%s", req.Email)
	sessionInfoJSON, err := h.Redis.Get(ctx, sessionInfoKey).Result()
	saveSession := true
	expectedUserID := 0

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
		h.Redis.Del(ctx, sessionInfoKey)
	}

	var user models.User
	err = h.DB.QueryRow(
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

	if expectedUserID > 0 && user.ID != expectedUserID {
		http.Error(w, "Code verification failed: user mismatch", http.StatusUnauthorized)
		return
	}

	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &models.Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(h.JWTKey)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	if saveSession && h.Redis != nil {
		if err := session.SaveToRedis(h.Redis, user.ID, tokenString, expirationTime); err != nil {
			log.Printf("Warning: Failed to save session to Redis: %v", err)
		}
	}

	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = utils.GetCurrentSemester(user.EnrollmentYear)
	}

	response := models.AuthResponse{Token: tokenString, User: user}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}
