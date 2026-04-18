package survey

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"

	"backend/internal/middleware"
	"backend/internal/models"
	"backend/internal/services/utils"
)

// Handler содержит зависимости для survey handlers
type Handler struct {
	DB *sql.DB
}

// CreateSurvey создаёт новый опрос
func (h *Handler) CreateSurvey(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var survey models.Survey
	if err := json.NewDecoder(r.Body).Decode(&survey); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	questionsJSON, err := json.Marshal(survey.Questions)
	if err != nil {
		http.Error(w, "Failed to serialize questions", http.StatusInternalServerError)
		return
	}

	err = h.DB.QueryRow(
		`INSERT INTO surveys (title, description, questions, created_by, image_url, end_date) 
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, created_at`,
		survey.Title, survey.Description, questionsJSON, claims.UserID, survey.ImageURL, survey.EndDate,
	).Scan(&survey.ID, &survey.CreatedAt)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"id":          survey.ID,
		"description": survey.Description,
		"questions":   survey.Questions,
		"created_by":  survey.CreatedBy,
		"created_at":  survey.CreatedAt,
		"is_active":   survey.IsActive,
	}

	var title interface{} = survey.Title
	var titleMap map[string]interface{}
	if json.Unmarshal([]byte(survey.Title), &titleMap) == nil {
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

// GetSurveys возвращает все активные опросы
func (h *Handler) GetSurveys(w http.ResponseWriter, r *http.Request) {
	rows, err := h.DB.Query(`
        SELECT id, title, description, questions, created_by, created_at, image_url, end_date 
        FROM surveys WHERE is_active = true ORDER BY created_at DESC
    `)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type SurveyWithStats struct {
		ID            int                `json:"id"`
		Title         interface{}        `json:"title"`
		Description   string             `json:"description"`
		Questions     []models.Question  `json:"questions"`
		CreatedBy     int                `json:"created_by"`
		CreatedAt     time.Time          `json:"created_at"`
		IsActive      bool               `json:"is_active"`
		ImageURL      string             `json:"image_url,omitempty"`
		EndDate       *time.Time         `json:"end_date,omitempty"`
		ResponseCount int                `json:"response_count"`
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

		var title interface{} = titleStr
		var titleMap map[string]interface{}
		if json.Unmarshal([]byte(titleStr), &titleMap) == nil {
			title = titleMap
		}

		var questions []models.Question
		if err := json.Unmarshal(questionsJSON, &questions); err != nil {
			http.Error(w, "Failed to parse questions", http.StatusInternalServerError)
			return
		}

		var endDatePtr *time.Time
		if endDate.Valid {
			endDatePtr = &endDate.Time
		}

		var responseCount int
		h.DB.QueryRow("SELECT COUNT(*) FROM user_responses WHERE survey_id = $1", surveyID).Scan(&responseCount)

		sws := SurveyWithStats{
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
			sws.ImageURL = imageURL.String
		}
		if endDatePtr != nil {
			sws.EndDate = endDatePtr
		}
		surveysWithStats = append(surveysWithStats, sws)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(surveysWithStats)
}

// SubmitSurvey сохраняет ответы на опрос
func (h *Handler) SubmitSurvey(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
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

	var alreadySubmitted bool
	err := h.DB.QueryRow(
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

	tx, err := h.DB.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	_, err = tx.Exec(
		"INSERT INTO user_responses (user_id, survey_id, answers) VALUES ($1, $2, $3)",
		claims.UserID, submission.SurveyID, answersJSON,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var pointsToAdd int
	err = tx.QueryRow("SELECT points FROM survey_points WHERE survey_id = $1", submission.SurveyID).Scan(&pointsToAdd)
	if err != nil {
		if err == sql.ErrNoRows {
			pointsToAdd = len(submission.Answers)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	_, err = tx.Exec("UPDATE users SET points = points + $1 WHERE id = $2", pointsToAdd, claims.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var user models.User
	err = h.DB.QueryRow(
		`SELECT id, username, email, first_name, last_name, study_group, enrollment_year, points 
		 FROM users WHERE id = $1`,
		claims.UserID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.FirstName, &user.LastName,
		&user.StudyGroup, &user.EnrollmentYear, &user.Points)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if user.EnrollmentYear > 0 {
		user.Course, user.Semester = utils.GetCurrentSemester(user.EnrollmentYear)
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

// SetSurveyPoints устанавливает баллы за опрос
func (h *Handler) SetSurveyPoints(w http.ResponseWriter, r *http.Request) {
	var request struct {
		SurveyID int `json:"survey_id"`
		Points   int `json:"points"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var exists bool
	err := h.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM survey_points WHERE survey_id = $1)", request.SurveyID).Scan(&exists)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if exists {
		_, err = h.DB.Exec("UPDATE survey_points SET points = $1 WHERE survey_id = $2", request.Points, request.SurveyID)
	} else {
		_, err = h.DB.Exec("INSERT INTO survey_points (survey_id, points) VALUES ($1, $2)", request.SurveyID, request.Points)
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Survey points updated successfully"})
}

// GetSurveyStatistics возвращает статистику по опросу
func (h *Handler) GetSurveyStatistics(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	surveyID, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid survey ID", http.StatusBadRequest)
		return
	}

	var survey models.Survey
	var questionsJSON []byte
	err = h.DB.QueryRow(`
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

	rows, err := h.DB.Query(`SELECT answers FROM user_responses WHERE survey_id = $1`, surveyID)
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
		for _, option := range question.Options {
			optionCounts[option] = 0
		}

		for _, userAnswers := range allAnswers {
			if i < len(userAnswers) {
				if answerIndex, ok := userAnswers[i].(float64); ok && int(answerIndex) >= 0 && int(answerIndex) < len(question.Options) {
					option := question.Options[int(answerIndex)]
					optionCounts[option]++
				}
			}
		}

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
