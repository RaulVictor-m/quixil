# Quixil Text Editor

Quixil is meant to be a text editor configured in the suckless style, which means source
code. But the main idea behind this is trying to laverage zig's compile time features
to create a kind of pluggin system where the API is just enough to create anything and
therefore you can just extend the editor without really patching it, the only files you shall
ever mess with is your own config.zig and what ever pluggins you want to craft, which will be made
in zig itself and statically included in the editor's code at compile time using some zig magic.

But as of now this is only an idea, keep an eye on it if you are interested.

## Objective

In the short term the objective is create a kind of backend for the text editor
with a satisfing API, and be able to cover all of it in test cases so that the behavior
keeps itself consistent
