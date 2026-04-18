package router

import (
	"database/sql"
	"fmt"
	"net/http"

	"github.com/go-redis/redis/v8"
	"github.com/gorilla/mux"

	"backend/internal/handlers/auth"
	"backend/internal/handlers/event"
	"backend/internal/handlers/product"
	"backend/internal/handlers/survey"
	"backend/internal/handlers/user"
	"backend/internal/middleware"
)

// SetupRouter создаёт и настраивает маршрутизатор
func SetupRouter(db *sql.DB, redisClient *redis.Client, jwtKey []byte) *mux.Router {
	router := mux.NewRouter()
	router.Use(middleware.CORS)
	router.Use(middleware.UTF8)

	jwtMw := middleware.JWT(jwtKey, redisClient)

	authHandler := &auth.Handler{DB: db, Redis: redisClient, JWTKey: jwtKey}
	userHandler := &user.Handler{DB: db, JWTKey: jwtKey}
	surveyHandler := &survey.Handler{DB: db}
	eventHandler := &event.Handler{DB: db}
	productHandler := &product.Handler{DB: db}

	// Auth routes
	router.HandleFunc("/register", authHandler.Register).Methods("POST", "OPTIONS")
	router.HandleFunc("/login", authHandler.Login).Methods("POST", "OPTIONS")
	router.HandleFunc("/request-code", authHandler.RequestCode).Methods("POST", "OPTIONS")
	router.HandleFunc("/verify-code", authHandler.VerifyCode).Methods("POST", "OPTIONS")
	router.Handle("/logout", jwtMw(http.HandlerFunc(authHandler.Logout))).Methods("POST", "OPTIONS")

	// Health check
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprint(w, "DB connection error")
			return
		}
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	}).Methods("GET")

	// User routes
	router.Handle("/users", jwtMw(http.HandlerFunc(userHandler.GetUsers))).Methods("GET", "OPTIONS")
	router.Handle("/current-user", jwtMw(http.HandlerFunc(userHandler.GetCurrentUser))).Methods("GET", "OPTIONS")
	router.Handle("/profile", jwtMw(http.HandlerFunc(userHandler.GetProfile))).Methods("GET", "OPTIONS")
	router.Handle("/profile-update", jwtMw(http.HandlerFunc(userHandler.UpdateProfile))).Methods("POST", "OPTIONS")
	router.Handle("/add-points", jwtMw(http.HandlerFunc(userHandler.AddPoints))).Methods("POST", "OPTIONS")

	// Survey routes
	router.Handle("/surveys", jwtMw(http.HandlerFunc(surveyHandler.GetSurveys))).Methods("GET", "OPTIONS")
	router.Handle("/createsurvey", jwtMw(middleware.Admin(http.HandlerFunc(surveyHandler.CreateSurvey)))).Methods("POST", "OPTIONS")
	router.Handle("/submitsurvey", jwtMw(http.HandlerFunc(surveyHandler.SubmitSurvey))).Methods("POST", "OPTIONS")
	router.Handle("/surveys/{id}/statistics", jwtMw(middleware.Admin(http.HandlerFunc(surveyHandler.GetSurveyStatistics)))).Methods("GET", "OPTIONS")
	router.Handle("/set-survey-points", jwtMw(middleware.Admin(http.HandlerFunc(surveyHandler.SetSurveyPoints)))).Methods("POST", "OPTIONS")

	// Event routes
	router.Handle("/events", jwtMw(http.HandlerFunc(eventHandler.GetEvents))).Methods("GET", "OPTIONS")
	router.Handle("/createevent", jwtMw(middleware.Admin(http.HandlerFunc(eventHandler.CreateEvent)))).Methods("POST", "OPTIONS")
	router.Handle("/events/{id}", jwtMw(middleware.Admin(http.HandlerFunc(eventHandler.UpdateEvent)))).Methods("PUT", "OPTIONS")
	router.Handle("/events/{id}", jwtMw(middleware.Admin(http.HandlerFunc(eventHandler.DeleteEvent)))).Methods("DELETE", "OPTIONS")

	// Product routes
	router.Handle("/products", jwtMw(http.HandlerFunc(productHandler.GetProducts))).Methods("GET", "OPTIONS")
	router.Handle("/createproduct", jwtMw(middleware.Admin(http.HandlerFunc(productHandler.CreateProduct)))).Methods("POST", "OPTIONS")
	router.Handle("/products/{id}", jwtMw(middleware.Admin(http.HandlerFunc(productHandler.UpdateProduct)))).Methods("PUT", "OPTIONS")
	router.Handle("/products/{id}", jwtMw(middleware.Admin(http.HandlerFunc(productHandler.DeleteProduct)))).Methods("DELETE", "OPTIONS")

	return router
}
