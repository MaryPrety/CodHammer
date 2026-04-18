package models

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
)

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

// Survey структура опроса
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

// UnmarshalJSON кастомный парсинг для Survey
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

	if aux.Title != nil {
		switch v := aux.Title.(type) {
		case string:
			s.Title = v
		case map[string]interface{}:
			titleJSON, err := json.Marshal(v)
			if err != nil {
				return fmt.Errorf("cannot marshal title: %v", err)
			}
			s.Title = string(titleJSON)
		default:
			s.Title = fmt.Sprintf("%v", v)
		}
	}

	if aux.EndDate != nil && *aux.EndDate != "" {
		endDateStr := *aux.EndDate
		if strings.HasSuffix(endDateStr, "Z") || (len(endDateStr) > 6 && (strings.Contains(endDateStr[len(endDateStr)-6:], "+") || strings.Contains(endDateStr[len(endDateStr)-6:], "-"))) {
			t, err := time.Parse(time.RFC3339, endDateStr)
			if err != nil {
				return fmt.Errorf("cannot parse end_date: %v", err)
			}
			s.EndDate = &t
		} else {
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
		s.EndDate = nil
	}

	return nil
}

// Question структура вопроса
type Question struct {
	ID      int      `json:"id"`
	Text    string   `json:"text"`
	Type    string   `json:"type"`
	Options []string `json:"options,omitempty"`
}

// SurveyResponse структура для хранения ответов
type SurveyResponse struct {
	UserID    int       `json:"user_id"`
	SurveyID  int       `json:"survey_id"`
	Answers   []int     `json:"answers"`
	CreatedAt time.Time `json:"created_at"`
}

// Event структура для хранения событий
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

// UnmarshalJSON кастомный парсинг для Event
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

	parseDateTime := func(dateStr string) (time.Time, error) {
		if strings.HasSuffix(dateStr, "Z") || (len(dateStr) > 6 && (strings.Contains(dateStr[len(dateStr)-6:], "+") || strings.Contains(dateStr[len(dateStr)-6:], "-"))) {
			return time.Parse(time.RFC3339, dateStr)
		}
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

// Product структура для хранения товаров
type Product struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"created_at"`
}
