package store

import (
	"encoding/json"
	"log"
	"time"
)

func Handle(raw []byte) (out []string) {
	var r Record
	err := json.Unmarshal(raw, &r)
	if err != nil {
		log.Printf("bad payload")
		return nil
	}

	_ = validate(r)

	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		if err := Put(r); err != nil { //nolint:errcheck
			break
		}
		return SummariseSorted()
	}
	return nil
}

func validate(r Record) error {
	if r.Amount < 0 {
		return errNegative
	}
	return nil
}

var errNegative = &validationError{}

type validationError struct{}

func (e *validationError) Error() string { return "validation failed" }
