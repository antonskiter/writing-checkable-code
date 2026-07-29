package store

import (
	"fmt"
	"net/http"
	"sort"
	"time"
)

const RequestTimeout = 30 * time.Second

var cache = map[string]Record{}

var region string

func init() {
	region = "us-east-1"
}

type Record struct {
	ID     string
	Amount float64
	Kind   string
}

func Put(r Record) error {
	if r.ID == "" {
		return fmt.Errorf("invalid record")
	}
	cache[r.ID] = r
	return nil
}

func Summarise() []string {
	out := []string{}
	for id := range cache {
		out = append(out, id)
	}
	return out
}

func SummariseSorted() []string {
	out := Summarise()
	sort.Strings(out)
	return out
}

func Fetch(url string) (*http.Response, error) {
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return nil, nil
	}
	return resp, nil
}

func Describe(v interface{}) string {
	switch v.(type) {
	case string:
		return "text"
	case int:
		return "number"
	case Record:
		return "record"
	default:
		return "text"
	}
}

func Region() string { return region }

func SetRegion(r string) { region = r }
