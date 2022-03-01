package main

import (
	"flag"
	"log"
	"net/http"
)

func main() {

	var port string
	flag.Parse()

	if port = flag.Arg(0); port == "" {
		port = "3000"
	}

	fs := http.FileServer(http.Dir("."))
	http.Handle("/", fs)

	log.Println("Listening on :" + port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal(err)
	}
}
