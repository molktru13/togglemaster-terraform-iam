package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	app := &App{}
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	app.healthHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("Esperado status 200, obteve %d", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), `"status":"ok"`) {
		t.Errorf("Resposta inesperada: %s", rec.Body.String())
	}
}

func TestGetDeterministicBucket(t *testing.T) {
	bucket1 := getDeterministicBucket("user-123enable-checkout")
	bucket2 := getDeterministicBucket("user-123enable-checkout")

	if bucket1 != bucket2 {
		t.Errorf("Bucket deve ser determinístico: %d != %d", bucket1, bucket2)
	}
	if bucket1 < 0 || bucket1 >= 100 {
		t.Errorf("Bucket fora do intervalo [0, 99]: %d", bucket1)
	}
}

func TestRunEvaluationLogic(t *testing.T) {
	app := &App{}

	// Flag desabilitada deve retornar false
	disabledInfo := &CombinedFlagInfo{
		Flag: &Flag{Name: "flag-off", IsEnabled: false},
	}
	if app.runEvaluationLogic(disabledInfo, "user-1") {
		t.Errorf("Flag desabilitada deveria retornar false")
	}

	// Flag habilitada sem regra deve retornar true
	enabledNoRule := &CombinedFlagInfo{
		Flag: &Flag{Name: "flag-on", IsEnabled: true},
		Rule: nil,
	}
	if !app.runEvaluationLogic(enabledNoRule, "user-1") {
		t.Errorf("Flag habilitada sem regra deveria retornar true")
	}

	// Regra 100% deve retornar true
	rule100 := &CombinedFlagInfo{
		Flag: &Flag{Name: "flag-100", IsEnabled: true},
		Rule: &TargetingRule{
			FlagName:  "flag-100",
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(100)},
		},
	}
	if !app.runEvaluationLogic(rule100, "user-any") {
		t.Errorf("Regra de 100%% deveria retornar true")
	}
}
