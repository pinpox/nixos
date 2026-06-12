// nats-auth-callout: a NATS auth-callout service that authenticates clients and
// leaf nodes by validating an OIDC id_token (e.g. from Gitea) against the
// provider's JWKS and minting a scoped NATS user JWT. Identity and group
// membership come from the OIDC provider, so adding/removing access never
// touches the NATS server config.
//
// Flow (centralized / config mode):
//   - the NATS server publishes a signed AuthorizationRequestClaims to
//     $SYS.REQ.USER.AUTH in the AUTH account; ConnectOptions.Token carries the
//     client's id_token.
//   - we verify that token offline against the provider's JWKS (iss/aud/exp/
//     signature), read the username + groups claims, map them to NATS
//     permissions, and return an AuthorizationResponseClaims with a signed
//     user JWT.
//
// Config via env (secrets may be passed as $<NAME>_FILE for systemd creds):
//   CALLOUT_NATS_URL          nats://127.0.0.1:4222
//   CALLOUT_CONN_NKEY_SEED    nkey seed for the callout's own AUTH-account login
//   CALLOUT_CREDS / _USER/_PASS  alternative login for the callout connection
//   CALLOUT_ACCOUNT_SEED      issuer account nkey SEED (signs user JWTs)   [required]
//   CALLOUT_XKEY_SEED         xkey SEED to decrypt requests (optional)
//   CALLOUT_OIDC_ISSUER       https://git.0cx.de                           [required]
//   CALLOUT_OIDC_AUDIENCE     the OAuth client_id the id_token was issued for [required]
//   CALLOUT_TARGET_ACCOUNT    account to bind users into (default TEAM)
//   CALLOUT_USERNAME_CLAIM    claim used as <user> in subjects (default preferred_username)
//   CALLOUT_REQUIRED_GROUP    if set, the token must carry this group (default none)
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/nats-io/jwt/v2"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nkeys"
)

const authCalloutSubject = "$SYS.REQ.USER.AUTH"

// xkey header the server sets on the request when encryption is enabled.
const serverXKeyHeader = "Nats-Server-Xkey"

type config struct {
	natsURL       string
	creds         string
	user, pass    string
	accountSeed   string
	xkeySeed      string
	connNkeySeed  string
	issuer        string
	audience      string
	targetAccount string
	usernameClaim string
	requiredGroup string
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func mustEnv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("missing required env %s", k)
	}
	return v
}

// secret reads a value from $<k>_FILE (trimmed) if set, else $<k>. This lets
// systemd LoadCredential expose seeds as files without them transiting env or
// the process table.
func secret(k string) string {
	if f := os.Getenv(k + "_FILE"); f != "" {
		b, err := os.ReadFile(f)
		if err != nil {
			log.Fatalf("read %s_FILE (%s): %v", k, f, err)
		}
		return strings.TrimSpace(string(b))
	}
	return os.Getenv(k)
}

func main() {
	cfg := config{
		natsURL:       env("CALLOUT_NATS_URL", "nats://127.0.0.1:4222"),
		creds:         os.Getenv("CALLOUT_CREDS"),
		user:          os.Getenv("CALLOUT_USER"),
		pass:          os.Getenv("CALLOUT_PASS"),
		accountSeed:   secret("CALLOUT_ACCOUNT_SEED"),
		xkeySeed:      secret("CALLOUT_XKEY_SEED"),
		connNkeySeed:  secret("CALLOUT_CONN_NKEY_SEED"),
		issuer:        mustEnv("CALLOUT_OIDC_ISSUER"),
		audience:      mustEnv("CALLOUT_OIDC_AUDIENCE"),
		targetAccount: env("CALLOUT_TARGET_ACCOUNT", "TEAM"),
		usernameClaim: env("CALLOUT_USERNAME_CLAIM", "preferred_username"),
		requiredGroup: os.Getenv("CALLOUT_REQUIRED_GROUP"),
	}

	akp, err := nkeys.FromSeed([]byte(cfg.accountSeed))
	if err != nil {
		log.Fatalf("invalid CALLOUT_ACCOUNT_SEED: %v", err)
	}

	var xkp nkeys.KeyPair
	if cfg.xkeySeed != "" {
		xkp, err = nkeys.FromCurveSeed([]byte(cfg.xkeySeed))
		if err != nil {
			log.Fatalf("invalid CALLOUT_XKEY_SEED: %v", err)
		}
	}

	// OIDC verifier: fetches the provider's JWKS via discovery and checks
	// iss/aud/exp/signature on every token, offline thereafter.
	ctx := context.Background()
	provider, err := oidc.NewProvider(ctx, cfg.issuer)
	if err != nil {
		log.Fatalf("oidc discovery for %s: %v", cfg.issuer, err)
	}
	verifier := provider.Verifier(&oidc.Config{ClientID: cfg.audience})

	opts := []nats.Option{nats.Name("nats-auth-callout")}
	switch {
	case cfg.connNkeySeed != "":
		ckp, err := nkeys.FromSeed([]byte(cfg.connNkeySeed))
		if err != nil {
			log.Fatalf("invalid CALLOUT_CONN_NKEY_SEED: %v", err)
		}
		cpub, _ := ckp.PublicKey()
		opts = append(opts, nats.Nkey(cpub, func(nonce []byte) ([]byte, error) {
			return ckp.Sign(nonce)
		}))
	case cfg.creds != "":
		opts = append(opts, nats.UserCredentials(cfg.creds))
	case cfg.user != "":
		opts = append(opts, nats.UserInfo(cfg.user, cfg.pass))
	}
	nc, err := nats.Connect(cfg.natsURL, opts...)
	if err != nil {
		log.Fatalf("connect %s: %v", cfg.natsURL, err)
	}
	defer nc.Close()

	h := &handler{cfg: cfg, akp: akp, xkp: xkp, verifier: verifier}
	if _, err := nc.Subscribe(authCalloutSubject, h.handle); err != nil {
		log.Fatalf("subscribe %s: %v", authCalloutSubject, err)
	}
	log.Printf("nats-auth-callout ready: issuer=%s audience=%s account=%s", cfg.issuer, cfg.audience, cfg.targetAccount)
	select {}
}

type handler struct {
	cfg      config
	akp      nkeys.KeyPair
	xkp      nkeys.KeyPair
	verifier *oidc.IDTokenVerifier
}

func (h *handler) handle(m *nats.Msg) {
	data := m.Data

	// Decrypt the request if the server sent it encrypted.
	if h.xkp != nil {
		serverXKey := m.Header.Get(serverXKeyHeader)
		if serverXKey != "" {
			dec, err := h.xkp.Open(data, serverXKey)
			if err != nil {
				log.Printf("decrypt request: %v", err)
				return
			}
			data = dec
		}
	}

	req, err := jwt.DecodeAuthorizationRequestClaims(string(data))
	if err != nil {
		log.Printf("decode auth request: %v", err)
		return
	}

	userJWT, errStr := h.authorize(req)
	if errStr != "" {
		log.Printf("denied (kind=%s): %s", req.ClientInformation.Kind, errStr)
	}
	h.respond(m, req, userJWT, errStr)
}

// authorize verifies the id_token against the JWKS and builds a scoped user JWT.
func (h *handler) authorize(req *jwt.AuthorizationRequestClaims) (string, string) {
	token := req.ConnectOptions.Token
	if token == "" {
		// Some clients send the token in the password field.
		token = req.ConnectOptions.Password
	}
	if token == "" {
		return "", "no token presented"
	}

	idToken, err := h.verifier.Verify(context.Background(), token)
	if err != nil {
		return "", fmt.Sprintf("token verification failed: %v", err)
	}

	var claims map[string]any
	if err := idToken.Claims(&claims); err != nil {
		return "", fmt.Sprintf("decode claims: %v", err)
	}

	user, _ := claims[h.cfg.usernameClaim].(string)
	if user == "" {
		return "", fmt.Sprintf("token missing %q claim", h.cfg.usernameClaim)
	}
	user = sanitize(user)

	groups := toStringSlice(claims["groups"])
	if h.cfg.requiredGroup != "" && !contains(groups, h.cfg.requiredGroup) {
		return "", fmt.Sprintf("user %q lacks required group %q", user, h.cfg.requiredGroup)
	}

	uc := jwt.NewUserClaims(req.UserNkey)
	uc.Audience = h.cfg.targetAccount
	uc.Name = user
	// Provenance-by-subject: this identity may publish only its own
	// team.<user>.> namespace, and read the team + shared buses.
	uc.Permissions.Pub.Allow = jwt.StringList{"team." + user + ".>"}
	uc.Permissions.Sub.Allow = jwt.StringList{"team.>", "shared.>", "_INBOX.>"}

	ujwt, err := uc.Encode(h.akp)
	if err != nil {
		return "", fmt.Sprintf("encode user jwt: %v", err)
	}
	log.Printf("authorized %s (kind=%s) -> team.%s.>", user, req.ClientInformation.Kind, user)
	return ujwt, ""
}

func (h *handler) respond(m *nats.Msg, req *jwt.AuthorizationRequestClaims, userJWT, errStr string) {
	arc := jwt.NewAuthorizationResponseClaims(req.UserNkey)
	arc.Audience = req.Server.ID
	if errStr != "" {
		arc.Error = errStr
	} else {
		arc.Jwt = userJWT
	}

	tok, err := arc.Encode(h.akp)
	if err != nil {
		log.Printf("encode response: %v", err)
		return
	}

	out := []byte(tok)
	if h.xkp != nil && req.Server.XKey != "" {
		sealed, err := h.xkp.Seal(out, req.Server.XKey)
		if err != nil {
			log.Printf("encrypt response: %v", err)
			return
		}
		out = sealed
	}
	_ = m.Respond(out)
}

// sanitize keeps a username safe to embed in a NATS subject token.
func sanitize(s string) string {
	return strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '-', r == '_':
			return r
		default:
			return '_'
		}
	}, s)
}

func contains(xs []string, x string) bool {
	for _, v := range xs {
		if v == x {
			return true
		}
	}
	return false
}

// toStringSlice coerces a claim that may be []any, []string, or a single
// string into []string.
func toStringSlice(v any) []string {
	switch t := v.(type) {
	case []string:
		return t
	case string:
		return []string{t}
	case []any:
		out := make([]string, 0, len(t))
		for _, e := range t {
			if s, ok := e.(string); ok {
				out = append(out, s)
			}
		}
		return out
	case json.RawMessage:
		var s []string
		_ = json.Unmarshal(t, &s)
		return s
	}
	return nil
}
