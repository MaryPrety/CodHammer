package user

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/dgrijalva/jwt-go"

	"backend/internal/middleware"
	"backend/internal/models"
	"backend/internal/services/utils"
)

// Handler содержит зависимости для user handlers
type Handler struct {
	DB     *sql.DB
	JWTKey []byte
}

// GetUsers возвращает список всех пользователей
func (h *Handler) GetUsers(w http.ResponseWriter, r *http.Request) {
	rows, err := h.DB.Query(`SELECT id, username, email, role, age, phone, first_name, last_name, 
		study_group, enrollment_year, points, created_at FROM users`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var u models.User
		if err := rows.Scan(&u.ID, &u.Username, &u.Email, &u.Role, &u.Age,
			&u.Phone, &u.FirstName, &u.LastName, &u.StudyGroup,
			&u.EnrollmentYear, &u.Points, &u.CreatedAt); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if u.EnrollmentYear > 0 {
			u.Course, u.Semester = utils.GetCurrentSemester(u.EnrollmentYear)
		}
		users = append(users, u)
	}
	if err = rows.Err(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// GetCurrentUser возвращает текущего пользователя по токену
func (h *Handler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
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
		return h.JWTKey, nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var user models.User
	err = h.DB.QueryRow(
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

	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = utils.GetCurrentSemester(user.EnrollmentYear)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// GetProfile возвращает профиль пользователя
func (h *Handler) GetProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var user models.User
	err := h.DB.QueryRow(`
        SELECT id, username, email, age, phone, points, created_at, 
		first_name, last_name, study_group, enrollment_year, educational_institution, educational_direction, role
        FROM users WHERE id = $1
    `, claims.UserID).Scan(
		&user.ID, &user.Username, &user.Email,
		&user.Age, &user.Phone, &user.Points, &user.CreatedAt,
		&user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear, &user.EducationalInstitution, &user.EducationalDirection, &user.Role,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = utils.GetCurrentSemester(user.EnrollmentYear)
	}

	var interestsJSON []byte
	var interests []string
	err = h.DB.QueryRow("SELECT interests FROM user_interests WHERE user_id = $1", claims.UserID).Scan(&interestsJSON)
	if err == nil {
		json.Unmarshal(interestsJSON, &interests)
	} else if err == sql.ErrNoRows {
		interests = []string{}
	} else {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var stats struct {
		Polls       float64 `json:"polls"`
		Hackathons  float64 `json:"hackathons"`
		Attendance  float64 `json:"attendance"`
		Conferences float64 `json:"conferences"`
		Bet         float64 `json:"bet"`
	}
	err = h.DB.QueryRow(`SELECT polls, hackathons, attendance, conferences, bet FROM user_stats WHERE user_id = $1`, claims.UserID).Scan(
		&stats.Polls, &stats.Hackathons, &stats.Attendance, &stats.Conferences, &stats.Bet,
	)
	if err != nil && err != sql.ErrNoRows {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rows, err := h.DB.Query(`SELECT day, attendance, hackathons, polls FROM weekly_activity WHERE user_id = $1`, claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	daysOfWeek := []string{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
	weeklyActivityMap := make(map[string]map[string]interface{})
	for _, day := range daysOfWeek {
		weeklyActivityMap[day] = map[string]interface{}{
			"day":        day,
			"attendance": 0,
			"hackathons": 0,
			"polls":      0,
		}
	}

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

	var weeklyActivity []map[string]interface{}
	for _, day := range daysOfWeek {
		weeklyActivity = append(weeklyActivity, weeklyActivityMap[day])
	}

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

// UpdateProfile обновляет профиль пользователя
func (h *Handler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
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

	tx, err := h.DB.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	_, err = tx.Exec(`
        UPDATE users SET username = $1, email = $2, age = $3, status = $4,
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
        INSERT INTO user_interests (user_id, interests) VALUES ($1, $2) 
        ON CONFLICT (user_id) DO UPDATE SET interests = $2
    `, claims.UserID, interestsJSON)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err = tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var user models.User
	err = h.DB.QueryRow(`
        SELECT id, username, email, age, phone, points, status, created_at,
               first_name, last_name, study_group, enrollment_year
        FROM users WHERE id = $1
    `, claims.UserID).Scan(
		&user.ID, &user.Username, &user.Email,
		&user.Age, &user.Phone, &user.Points, &user.Status, &user.CreatedAt,
		&user.FirstName, &user.LastName, &user.StudyGroup, &user.EnrollmentYear,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var interestsJSONResp []byte
	var interests []string
	err = h.DB.QueryRow("SELECT interests FROM user_interests WHERE user_id = $1", claims.UserID).Scan(&interestsJSONResp)
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

// AddPoints добавляет баллы пользователю
func (h *Handler) AddPoints(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var request struct {
		Points int `json:"points"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if request.Points <= 0 {
		http.Error(w, "Points must be positive", http.StatusBadRequest)
		return
	}

	_, err := h.DB.Exec("UPDATE users SET points = points + $1 WHERE id = $2", request.Points, claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var user models.User
	err = h.DB.QueryRow("SELECT id, username, email, points FROM users WHERE id = $1", claims.UserID).Scan(&user.ID, &user.Username, &user.Email, &user.Points)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"message":      "Points added successfully",
		"points_added": request.Points,
		"total_points": user.Points,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
