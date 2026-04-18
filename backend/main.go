package main

import (
	"log"
	"net/http"

	"backend/internal/config"
	"backend/internal/database"
	"backend/internal/router"
)

func main() {
	config.LoadEnv()
	jwtKey := config.GetJWTKey()

	db := database.InitDB()
	defer db.Close()

	redisClient := database.InitRedis()
	if redisClient != nil {
		defer redisClient.Close()
	}

	r := router.SetupRouter(db, redisClient, jwtKey)

	serverAddress := config.GetServerAddress()
	log.Printf("Server is running on %s", serverAddress)
	log.Fatal(http.ListenAndServe(":"+config.GetPort(), r))
}
