package main

import (
	"fmt"
	"log"
	"net/http"
)

type Server struct{}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message": "Hello World!"}`))
}

func main() {
	fmt.Println("main function started running")
	s := &Server{}
	http.Handle("/", s)
	log.Fatal(http.ListenAndServe(":8085", nil))
}
