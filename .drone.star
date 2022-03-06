def main(ctx):
  return {
    "kind": "pipeline",
    "name": "build",
	"type": "exec",
    "steps": [
      {
        "name": "test",
        "commands": [
            "echo hello world"
        ]
      }
    ]
  }
