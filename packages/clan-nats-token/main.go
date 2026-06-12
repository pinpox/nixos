// clan-nats-token: obtain and refresh an OIDC token for presenting to a
// NATS auth-callout. Two subcommands:
//
//	clan-nats-token login    one-time interactive login (auth-code + PKCE +
//	                         loopback redirect, since Gitea has no device flow).
//	                         Stores the refresh token in --state.
//	clan-nats-token token    print a fresh id_token (refresh grant). For headless
//	                         daemons/leaves run this on a timer; for a shell do
//	                         `nats --token "$(clan-nats-token token)"`.
//
// Config (flags or env CLAN_NATS_{ISSUER,CLIENT_ID,SCOPES,STATE,PORT}):
//
//	--issuer     OIDC issuer (e.g. https://git.0cx.de)
//	--client-id  the OAuth app client_id
//	--scopes     space-separated (default "openid profile groups offline_access")
//	--state      path to the refresh-token store (default $XDG_RUNTIME_DIR/clan-nats/token.json)
//	--port       loopback callback port (default 8765)
package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

type opts struct {
	issuer   string
	clientID string
	scopes   string
	state    string
	port     string
}

type stateFile struct {
	RefreshToken string `json:"refresh_token"`
	IDToken      string `json:"id_token,omitempty"`
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func defaultState() string {
	base := os.Getenv("XDG_RUNTIME_DIR")
	if base == "" {
		base = os.TempDir()
	}
	return filepath.Join(base, "clan-nats", "token.json")
}

func parseOpts(args []string) opts {
	o := opts{
		issuer:   env("CLAN_NATS_ISSUER", ""),
		clientID: env("CLAN_NATS_CLIENT_ID", ""),
		scopes:   env("CLAN_NATS_SCOPES", "openid profile groups offline_access"),
		state:    env("CLAN_NATS_STATE", defaultState()),
		port:     env("CLAN_NATS_PORT", "8765"),
	}
	for i := 0; i < len(args); i++ {
		next := func() string { i++; return args[i] }
		switch args[i] {
		case "--issuer":
			o.issuer = next()
		case "--client-id":
			o.clientID = next()
		case "--scopes":
			o.scopes = next()
		case "--state":
			o.state = next()
		case "--port":
			o.port = next()
		}
	}
	return o
}

func mustProvider(ctx context.Context, o opts) (*oidc.Provider, oauth2.Config) {
	if o.issuer == "" || o.clientID == "" {
		die("--issuer and --client-id are required")
	}
	provider, err := oidc.NewProvider(ctx, o.issuer)
	if err != nil {
		die("oidc discovery: %v", err)
	}
	cfg := oauth2.Config{
		ClientID:    o.clientID,
		Endpoint:    provider.Endpoint(),
		RedirectURL: fmt.Sprintf("http://127.0.0.1:%s/callback", o.port),
		Scopes:      strings.Fields(o.scopes),
	}
	return provider, cfg
}

func main() {
	if len(os.Args) < 2 {
		die("usage: clan-nats-token <login|token> [flags]")
	}
	o := parseOpts(os.Args[2:])
	ctx := context.Background()
	switch os.Args[1] {
	case "login":
		login(ctx, o)
	case "token":
		printToken(ctx, o)
	default:
		die("unknown subcommand %q", os.Args[1])
	}
}

func login(ctx context.Context, o opts) {
	_, cfg := mustProvider(ctx, o)

	verifier := oauth2.GenerateVerifier()
	stateTok := randString()

	codeCh := make(chan string, 1)
	errCh := make(chan error, 1)
	mux := http.NewServeMux()
	mux.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
		if e := r.URL.Query().Get("error"); e != "" {
			errCh <- fmt.Errorf("authorization error: %s", e)
			http.Error(w, e, http.StatusBadRequest)
			return
		}
		if r.URL.Query().Get("state") != stateTok {
			errCh <- fmt.Errorf("state mismatch")
			http.Error(w, "state mismatch", http.StatusBadRequest)
			return
		}
		fmt.Fprintln(w, "clan-nats: authorized, you can close this tab.")
		codeCh <- r.URL.Query().Get("code")
	})

	ln, err := net.Listen("tcp", "127.0.0.1:"+o.port)
	if err != nil {
		die("listen 127.0.0.1:%s: %v", o.port, err)
	}
	srv := &http.Server{Handler: mux}
	go srv.Serve(ln)
	defer srv.Close()

	authURL := cfg.AuthCodeURL(stateTok,
		oauth2.AccessTypeOffline,
		oauth2.S256ChallengeOption(verifier),
	)
	fmt.Fprintf(os.Stderr, "Open this URL to authorize:\n\n  %s\n\n", authURL)
	openBrowser(authURL)

	var code string
	select {
	case code = <-codeCh:
	case err := <-errCh:
		die("%v", err)
	case <-time.After(5 * time.Minute):
		die("timed out waiting for authorization")
	}

	tok, err := cfg.Exchange(ctx, code, oauth2.VerifierOption(verifier))
	if err != nil {
		die("code exchange: %v", err)
	}
	if tok.RefreshToken == "" {
		die("provider returned no refresh_token (request offline_access and a confidential-or-PKCE client)")
	}
	idt, _ := tok.Extra("id_token").(string)
	writeState(o.state, stateFile{RefreshToken: tok.RefreshToken, IDToken: idt})
	fmt.Fprintln(os.Stderr, "clan-nats: logged in; refresh token stored at "+o.state)
}

func printToken(ctx context.Context, o opts) {
	_, cfg := mustProvider(ctx, o)
	st := readState(o.state)
	if st.RefreshToken == "" {
		die("no refresh token; run `clan-nats-token login` first")
	}
	src := cfg.TokenSource(ctx, &oauth2.Token{RefreshToken: st.RefreshToken})
	tok, err := src.Token()
	if err != nil {
		die("refresh: %v", err)
	}
	idt, _ := tok.Extra("id_token").(string)
	if idt == "" {
		die("provider returned no id_token on refresh")
	}
	// Persist a rotated refresh token if the provider issued one.
	if tok.RefreshToken != "" && tok.RefreshToken != st.RefreshToken {
		st.RefreshToken = tok.RefreshToken
	}
	st.IDToken = idt
	writeState(o.state, st)
	fmt.Println(idt)
}

func writeState(path string, st stateFile) {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		die("mkdir state dir: %v", err)
	}
	b, _ := json.Marshal(st)
	if err := os.WriteFile(path, b, 0o600); err != nil {
		die("write state: %v", err)
	}
}

func readState(path string) stateFile {
	b, err := os.ReadFile(path)
	if err != nil {
		return stateFile{}
	}
	var st stateFile
	_ = json.Unmarshal(b, &st)
	return st
}

func openBrowser(url string) {
	var cmd string
	switch runtime.GOOS {
	case "darwin":
		cmd = "open"
	default:
		cmd = "xdg-open"
	}
	_ = exec.Command(cmd, url).Start()
}

func randString() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

func die(format string, a ...any) {
	fmt.Fprintf(os.Stderr, "clan-nats-token: "+format+"\n", a...)
	os.Exit(1)
}
