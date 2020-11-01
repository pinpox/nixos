# Krosse-Flagge Server


## The Lounge user setup

The `kfbox` server hosts an instance of [The Lounge](https://thelounge.chat/), a
IRC bouncer and client.

### New User Setup

1. Ask [pinpox](https://pablo.tools) for a account with the desired nickname.
A user with the needed permissions will create the user for you using this
command and give you a initial password for your user.

```bash
docker exec --user node -it thelounge thelounge add awesome-new-nickname
```
2. With the nickname and initial password, login at [The Lounge](https://irc.0cx.de).
3. You will be presented with a wizard to add IRC servers. The default is
   `freenode`.
4. Add your existing freenode account credentials to The Lounge. If you don't
   have a user on the `freenode` IRC server, you should now register one.
   The registration process is documented
   [here](https://freenode.net/kb/answer/registration#registering). To use [The
   lougne

3. Change your password to whatever you want, make it a good one.






4. Account auf [freenode registrieren]
```
/nick mein-freenode-nick
/msg NickServ REGISTER mein-frenode-passwort youremail@example.com
```
5. Freenode Account auf [The Lounge](https://irc.0cx.de) speichern (Freenode
   sollte im Wizard der Default sein, Freenode Nick und Passwort einfach
   eintragen)

6. Den Channel `#krosse-flagge` joinen (`/join #krosse-flagge`)
