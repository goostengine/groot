# Groot

<p align="center">
  <a href="https://github.com/goostengine">
    <img src="icon.svg" width="256" alt="Groot">
  </a>
</p>

**Groot** (Godot root testing) is a test framework for writing tests. Scenes are
treated as the first-class citizen for unit and integration testing over plain
scripts, with a great emphasis on the ease-of-use. The plugin aims to adapt and
integrate to the existing node-based approach for building games and other
applications in Godot Engine.

This is for you if you:
- are lazy to write tests;
- want improve prototyping robustness without compromising development speed;
- achieve easier maintenance of tests.

## Features

- A collection of common `assert` methods, a general-purpose `check` method to
  test simple assertions.
- Run and test individual scenes immediately upon creation with `F6`.
- Combine or organize your tests by adding test nodes as children.
- Test scenes can be parameterized with `export` keywords within scripts.
- Each individual test scene can be disabled in the inspector, `pending` scenes.
- No need to export scripts nor scenes in order for them to get tested in
  release builds.
- May work with any script type other than `GDScript` in the future (`C#` etc).
- Organize your tests by using multiple test trees (for instance, test rendering
  and data structures separately).

## Limitations

The simplified architecture comes with certain design decisions which might
limit the way you can utilize this for your own use cases:

- No support for mock objects (a.k.a `double`s in [Gut](https://github.com/bitwes/Gut))
- Method call counts and signal watching are not implemented
- No tight integration with the Godot Editor (as seen in [WAT](https://github.com/CodeDarigan/WAT))

## Non-goals

The framework aims to be minimalist, so the plugin does not provide all possible
assert functions which exist under the sun, such as `assert_string_not_empty()`.
In fact, we recommend you to use the main `check()` method for all assertions.
If you need more sophisticated approach, consider using
[Gut](https://github.com/bitwes/Gut) or
[WAT](https://github.com/CodeDarigan/WAT) instead.
