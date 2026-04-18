package utils

import (
	"crypto/rand"
	"math/big"
	"strconv"
	"time"
)

// GenerateCode генерирует 6-значный код
func GenerateCode() (string, error) {
	code := ""
	for i := 0; i < 6; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		code += strconv.Itoa(int(n.Int64()))
	}
	return code, nil
}

// GetCurrentSemester вычисляет текущий курс и семестр по году поступления
func GetCurrentSemester(enrollmentYear int) (int, int) {
	now := time.Now()
	currentYear := now.Year()
	currentMonth := int(now.Month())

	course := currentYear - enrollmentYear
	if currentMonth >= 9 {
		course++
	}

	var semester int
	if currentMonth >= 2 && currentMonth <= 6 {
		semester = 2
	} else {
		semester = 1
	}

	return course, semester
}
