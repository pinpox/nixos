---
name: Shopping list
description: Keep the shopping list in ~/shopping-list.md, fed by the kitchen button and by chat
---

The shopping list is `~/shopping-list.md`: one item per line, written as
`- Item`. Create the file when it does not exist.

## Kitchen button

A trigger that starts with "Voice message from the kitchen button" is speech
from the push-to-talk button in the kitchen. Whisper transcribed it from
German, so a word can be misheard. Anyone in the kitchen can press it.

When the message names things to buy:

1. Split the text into items at commas and at "und".
2. Turn a misheard word into the grocery that sounds like it ("Hafer
   flocken" → "Haferflocken"). Keep quantities ("2 Liter Milch").
3. Skip an item that is already on the list.
4. Append the rest.
5. Reply with one line in German naming what you added, e.g.
   "Notiert: Milch, Eier."

Any other message is a request like one in chat: answer it or do it, in
German.

## Chat

When asked, show the list, remove what was bought, or clear it. Reply in the
language of the request.
