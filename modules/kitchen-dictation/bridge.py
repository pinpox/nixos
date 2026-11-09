"""Push-to-talk bridge from an ESPHome voice device to opencrow.

The bridge takes Home Assistant's place on the device's native API. It
collects the audio of one button press, transcribes it with faster-whisper
and writes the text as one line into opencrow's trigger pipe.
"""

import asyncio
import errno
import logging
import os
import sys

import numpy as np
from aioesphomeapi import APIClient, ReconnectLogic, VoiceAssistantEventType
from faster_whisper import WhisperModel

log = logging.getLogger("kitchen-dictation")

# 16 kHz, 16-bit mono: half a second is shorter than any item name.
MIN_BYTES = 16000

# Whisper copies the style of the prompt: commas between items, nouns
# capitalised, no sentence around them.
INITIAL_PROMPT = "Einkaufsliste: Milch, Eier, Butter, Haferflocken."
LANGUAGE = "de"


class Bridge:
    def __init__(self, client, model, pipe):
        self.client = client
        self.model = model
        self.pipe = pipe
        self.pcm = bytearray()
        self.listening = False

    def send(self, event, data=None):
        self.client.send_voice_assistant_event(event, data or {})

    def fail(self, code, message):
        log.warning("%s: %s", code, message)
        self.send(
            VoiceAssistantEventType.VOICE_ASSISTANT_ERROR,
            {"code": code, "message": message},
        )

    async def on_start(self, conversation_id, flags, settings, wake_word):
        self.pcm.clear()
        self.listening = True
        self.send(VoiceAssistantEventType.VOICE_ASSISTANT_RUN_START)
        self.send(VoiceAssistantEventType.VOICE_ASSISTANT_STT_START)
        # Port 0 asks the device to send its audio over the API connection.
        return 0

    async def on_audio(self, data, data2):
        if self.listening:
            self.pcm.extend(data)

    async def on_stop(self, abort):
        # The release of the button arrives as a stop request, which
        # aioesphomeapi reports as abort=True. It still ends the clip.
        if not self.listening:
            return
        self.listening = False
        pcm = bytes(self.pcm)
        self.pcm.clear()
        try:
            await self.finish(pcm)
        finally:
            self.send(VoiceAssistantEventType.VOICE_ASSISTANT_RUN_END)

    async def finish(self, pcm):
        if len(pcm) < MIN_BYTES:
            self.fail("too-short", f"{len(pcm)} bytes of audio")
            return
        text = await asyncio.to_thread(self.transcribe, pcm)
        if not text:
            self.fail("no-text", "whisper heard no speech")
            return
        log.info("heard: %s", text)
        try:
            self.write(text)
        except OSError as e:
            self.fail("pipe", str(e))
            return
        self.send(
            VoiceAssistantEventType.VOICE_ASSISTANT_STT_END, {"text": text}
        )

    def transcribe(self, pcm):
        audio = np.frombuffer(pcm, np.int16).astype(np.float32) / 32768
        segments, _ = self.model.transcribe(
            audio,
            language=LANGUAGE,
            vad_filter=True,
            initial_prompt=INITIAL_PROMPT,
        )
        return " ".join(" ".join(s.text for s in segments).split())

    def write(self, text):
        # O_NONBLOCK fails with ENXIO when opencrow does not hold the pipe
        # open, instead of blocking the bridge until it does.
        try:
            fd = os.open(self.pipe, os.O_WRONLY | os.O_NONBLOCK)
        except OSError as e:
            if e.errno == errno.ENXIO:
                raise OSError(e.errno, "opencrow is not reading") from e
            raise
        line = (
            "Voice message from the kitchen button (German speech-to-text, "
            f"may contain recognition errors): {text}\n"
        )
        with os.fdopen(fd, "w") as f:
            f.write(line)


async def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    device = os.environ["DEVICE"]
    pipe = os.environ["PIPE"]
    key_file = os.path.join(os.environ["CREDENTIALS_DIRECTORY"], "api-key")
    with open(key_file) as f:
        key = f.read().strip()

    log.info("loading whisper model %s", os.environ["MODEL"])
    model = WhisperModel(
        os.environ["MODEL"],
        device="cpu",
        compute_type="int8",
        download_root=os.environ.get("CACHE_DIRECTORY"),
    )

    client = APIClient(
        device, 6053, None, noise_psk=key, client_info="kitchen-dictation"
    )
    bridge = Bridge(client, model, pipe)

    async def on_connect():
        log.info("connected to %s", device)
        client.subscribe_voice_assistant(
            handle_start=bridge.on_start,
            handle_stop=bridge.on_stop,
            handle_audio=bridge.on_audio,
        )

    async def on_disconnect(expected):
        bridge.listening = False
        log.warning("disconnected from %s", device)

    # mDNS is not used: the device is reached by its fixed address.
    reconnect = ReconnectLogic(
        client=client,
        on_connect=on_connect,
        on_disconnect=on_disconnect,
        name=device,
        zeroconf_wake=False,
    )
    await reconnect.start()
    await asyncio.Event().wait()


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
