# DVD Screensaver on the NES
## What? Why?

I thought it'd be funny.  That's why.

# Assembling
## Requirements

- [cc65](https://cc65.github.io/)
- [GNU Make](https://www.gnu.org/software/make/)
- (optional) [ld65-labels](https://github.com/zorchenhimer/ld65-labels)

If you don't want or need debugging labels, edit the `Makefile` to remove the `.mlb` prerequisite from the `all` recipe.

## How Do

```
$ git clone https://github.com/zorchenhimer/nes-dvd-screensaver.git
$ cd nes-dvd-screensaver
$ make
```

After a successful `make` you'll have a `bin/` folder with a bunch of stuff in it, namely the `.nes` rom file.

# License

MIT license.  See `LICENSE.txt` for the full text.
