# Scrimblo

This plugin adds new and, hopefully, better ways to scramble teams in TF2. 

By default, TF2 scrambles work randomly, by shuffling the players around without regard to their performance, which often times leads to imbalanced teams. Instead, this plugin provides a method to shuffle the teams by a player's average score over the time they were playing. The players will be ranked based on how many points, on average, they scored each minute since they scored their first point, and then distributed equally.

This, theoretically, means that high performing players on the dominating team will be split, and that low performing players will be balanced between the two teams allowing them to contribute to their teams more over being stomped.

## Installation

Drop the `scrimblo.smx` plugin in your `addons/sourcemod/plugins` directory. This plugin does not require configuration.

## Usage 

**This plugin is not yet production ready! Use with caution.**

Use the `sm_scrimblo` admin command to scramble the teams manually.

Further integration, such as replacing `mp_scrambleteams` is planned. Scrambling options such as vote scramble and auto scramble will be a part of a separate plugin.

## Development

Use the provided `Makefile` to easily compile and distribute this plugin. By default, running `make` will compile all files in the `src/` directory and place the built binaries in the `build/` directory.

```bash
make COMPILER_DIR=/path/to/addons/sourcemod/scripting
```

Running `make release` will compile the plugin and compress the compiled plugin and all other usually distributed files (the source and any eventual configuration and translation files) into a single archive that you can deploy to your servers or share with your best friend.

If you wish to develop on Windows, please follow [this tutorial](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

## License

This plugin and the associated code is licensed under the [GNU General Public License v3](LICENSE).
