package email

import (
	"fmt"
	"log"
	"net/smtp"
	"os"
)

// SendCode отправляет код авторизации на email
func SendCode(email, code string) error {
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPassword := os.Getenv("SMTP_PASSWORD")
	fromEmail := os.Getenv("FROM_EMAIL")

	if smtpHost == "" {
		smtpHost = "smtp.gmail.com"
	}
	if smtpPort == "" {
		smtpPort = "587"
	}
	if fromEmail == "" {
		fromEmail = smtpUser
	}

	if smtpUser == "" || smtpPassword == "" {
		log.Printf("SMTP not configured. Email code for %s: %s", email, code)
		return nil
	}

	subject := "Код авторизации"
	body := fmt.Sprintf(`Здравствуйте!

Ваш код для входа в систему: %s

Код действителен в течение 10 минут.

Если вы не запрашивали этот код, проигнорируйте это письмо.`, code)

	message := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s",
		fromEmail, email, subject, body)

	auth := smtp.PlainAuth("", smtpUser, smtpPassword, smtpHost)
	addr := fmt.Sprintf("%s:%s", smtpHost, smtpPort)

	err := smtp.SendMail(addr, auth, fromEmail, []string{email}, []byte(message))
	if err != nil {
		return fmt.Errorf("failed to send email: %v", err)
	}
	return nil
}
