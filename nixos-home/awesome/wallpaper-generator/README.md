# Wallpaper generator

Generate random wallpapers from mathematical functions using a color palette (like
`~/.Xresources`).

Add your own generators in `wp-gen.lua`.

#### Harmonograph

<img src="./examples/harmonograph/1.png" width="30%"></img> 
<img src="./examples/harmonograph/2.png" width="30%"></img> 
<img src="./examples/harmonograph/3.png" width="30%"></img> 
<img src="./examples/harmonograph/4.png" width="30%"></img> 
<img src="./examples/harmonograph/5.png" width="30%"></img> 
<img src="./examples/harmonograph/6.png" width="30%"></img> 

#### Lines

<img src="./examples/lines/1.png" width="30%"></img> 
<img src="./examples/lines/2.png" width="30%"></img> 
<img src="./examples/lines/3.png" width="30%"></img> 

#### Batman Equation (because why not?)

<img src="./examples/batman/1.png" width="30%"></img> 
<img src="./examples/batman/2.png" width="30%"></img> 
<img src="./examples/batman/3.png" width="30%"></img> 

#### Pink Floyd

<img src="./examples/prisma/1.png" width="30%"></img> 

## Development

The project provides a [nix-shell]() with all necesary dependencies and some
helpers ready.


```bash
# Enter nix-shell
user@host: nix-shell

# Build the project
[nix-shell:~/path] build
```

There is also a helper function defined, that will allow you to live-preview the
generated image. It will run the script on each save and show the image
fullscreen.

```bash
# Enter nix-shell
user@host: nix-shell

# Preview a generated image
[nix-shell:~/path] preview generator-homograph.png
```
