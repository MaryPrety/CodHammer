package event

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gorilla/mux"

	"backend/internal/config"
	"backend/internal/middleware"
	"backend/internal/models"
)

// Handler содержит зависимости для event handlers
type Handler struct {
	DB *sql.DB
}

// cleanupOldEvents удаляет старые завершённые события
func (h *Handler) cleanupOldEvents() error {
	retentionDays := config.DefaultEventRetentionDays
	if envDays := os.Getenv("EVENT_RETENTION_DAYS"); envDays != "" {
		if days, err := strconv.Atoi(envDays); err == nil && days > 0 {
			retentionDays = days
		}
	}

	cutoffDate := time.Now().AddDate(0, 0, -retentionDays)

	result, err := h.DB.Exec(`
		DELETE FROM events 
		WHERE end_date IS NOT NULL AND end_date < $1
	`, cutoffDate)
	if err != nil {
		log.Printf("Error cleaning up old events: %v", err)
		return err
	}

	if rowsAffected, err := result.RowsAffected(); err == nil && rowsAffected > 0 {
		log.Printf("Cleaned up %d old events (older than %d days)", rowsAffected, retentionDays)
	}

	return nil
}

// CreateEvent создаёт новое событие
func (h *Handler) CreateEvent(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*models.Claims)
	if !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var event models.Event
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		log.Printf("Error decoding event: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if event.Type == "" {
		event.Type = "Conference"
	}

	err := h.DB.QueryRow(
		`INSERT INTO events (title, description, type, start_date, end_date, user_id) 
		VALUES ($1, $2, $3, $4, $5, $6) 
		RETURNING id, created_at`,
		event.Title, event.Description, event.Type, event.StartDate, event.EndDate, claims.UserID,
	).Scan(&event.ID, &event.CreatedAt)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(event)
}

// GetEvents возвращает все события
func (h *Handler) GetEvents(w http.ResponseWriter, r *http.Request) {
	h.cleanupOldEvents()

	rows, err := h.DB.Query(`
		SELECT id, title, description, type, start_date, end_date, user_id, created_at 
		FROM events ORDER BY start_date DESC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var events []models.Event
	for rows.Next() {
		var event models.Event
		if err := rows.Scan(
			&event.ID, &event.Title, &event.Description, &event.Type,
			&event.StartDate, &event.EndDate, &event.UserID, &event.CreatedAt,
		); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		events = append(events, event)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(events)
}

// UpdateEvent обновляет событие
func (h *Handler) UpdateEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	var event models.Event
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := h.DB.Exec(`
		UPDATE events 
		SET title = $1, description = $2, type = $3, start_date = $4, end_date = $5 
		WHERE id = $6`,
		event.Title, event.Description, event.Type, event.StartDate, event.EndDate, eventID,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// DeleteEvent удаляет событие
func (h *Handler) DeleteEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	_, err := h.DB.Exec(`DELETE FROM events WHERE id = $1`, eventID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}
