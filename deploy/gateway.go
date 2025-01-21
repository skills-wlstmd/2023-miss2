package main

import (
	"fmt"
	"net/http"
)

func gateway(w http.ResponseWriter, req *http.Request) {
    fmt.Fprint(w, "UP")
}

func health(w http.ResponseWriter, req *http.Request) {
    fmt.Fprint(w, "OK")
}

func main() {
    http.HandleFunc("/health", health)
    http.HandleFunc("/gateway", gateway)
    http.ListenAndServe(":8080", nil)
}