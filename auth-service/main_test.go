package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestGenerateAndHashAPIKey(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("Erro inesperado ao gerar chave: %v", err)
	}
	if !strings.HasPrefix(key, "tm_key_") {
		t.Errorf("Esperado prefixo tm_key_, obteve: %s", key)
	}

	hash := hashAPIKey(key)
	if len(hash) != 64 {
		t.Errorf("Esperado hash SHA-256 de 64 caracteres, obteve tamanho %d", len(hash))
	}

	// Determinismo do hash
	if hashAPIKey(key) != hash {
		t.Errorf("Hash SHA-256 deve ser determinístico")
	}
}

func TestHealthHandler(t *testing.T) {
	app := &App{MasterKey: "test-master-key"}
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	app.healthHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("Esperado status 200, obteve %d", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), `"status":"ok"`) {
		t.Errorf("Resposta inesperada no health check: %s", rec.Body.String())
	}
}

func TestMasterKeyMiddleware(t *testing.T) {
	app := &App{MasterKey: "secret-master"}
	protected := app.masterKeyAuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	// Teste sem autorização
	reqUnauthorized := httptest.NewRequest(http.MethodPost, "/admin/keys", nil)
	recUnauthorized := httptest.NewRecorder()
	protected.ServeHTTP(recUnauthorized, reqUnauthorized)
	if recUnauthorized.Code != http.StatusForbidden {
		t.Errorf("Esperado status 403, obteve %d", recUnauthorized.Code)
	}

	// Teste com autorização válida
	reqAuthorized := httptest.NewRequest(http.MethodPost, "/admin/keys", nil)
	reqAuthorized.Header.Set("Authorization", "Bearer secret-master")
	recAuthorized := httptest.NewRecorder()
	protected.ServeHTTP(recAuthorized, reqAuthorized)
	if recAuthorized.Code != http.StatusOK {
		t.Errorf("Esperado status 200, obteve %d", recAuthorized.Code)
	}
}
